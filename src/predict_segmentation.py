# Import libraries
import tensorflow as tf
from tensorflow import keras
import PIL
import numpy as np
import os
import sys

# Arguments
# w=1
# path_model = "D:\Projekte\\road_finder\model\\road_finder_model.h5"
# path_data = "D:\Projekte\\road_finder\wd\prediction\\1"
w = sys.argv[1]
path_model = sys.argv[2]
path_data = sys.argv[3]

# Set paths
path_pics = os.path.join(path_data, "pics")
path_masks = os.path.join(path_data, "masks")
if not os.path.exists(path_masks):
    os.mkdir(path_masks)

# Define image sizes
img_size_org = (512,512)
n_splits = 2
img_size = (np.rint(img_size_org[0]/n_splits).astype(int), np.rint(img_size_org[1]/n_splits).astype(int))

# Load model
model = keras.models.load_model(path_model, custom_objects={'loss': None, 'falsepos': None, 'falseneg': None, 'precision': None, 'recall': None, 'f1_score': None})

# Execute prediciton for all images in folder
if __name__== '__main__':
    included_extensions = [ 'jpg']
    files = [fn for fn in os.listdir(path_pics) if any(fn.endswith(ext) for ext in included_extensions)]

    for file in files:
        try:
            image = tf.io.read_file(os.path.join(path_pics,file))
            image = tf.image.decode_jpeg(image)
            image = tf.image.convert_image_dtype(image, tf.float32)
            image = tf.image.resize(image, img_size_org)
            patches_img = tf.image.extract_patches(tf.reshape(image, [1,img_size_org[0],img_size_org[1],1]), [1,img_size[0],img_size[1],1], [1,img_size[0],img_size[1],1], [1,1,1,1], padding="VALID")
            patches_img = tf.reshape(patches_img, [n_splits**2, img_size[0],img_size[1],1])
            pred = model.predict(patches_img)

            #np.unique(np.round(pred[2,:,:,0],2), return_counts=True)

            for i in range(n_splits*n_splits):
                img = keras.preprocessing.image.array_to_img(np.expand_dims(pred[i,:,:,1],-1))
                img = img.resize((150,150))
                img.save(os.path.join(path_masks, file.split(".")[0]+"_"+ str(i)+ ".jpg"))

        except Exception:
            print(file)

