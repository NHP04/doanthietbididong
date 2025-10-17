import torch
import torch.nn as nn
from torchvision.models import resnet50, ResNet50_Weights, efficientnet_b6, EfficientNet_B6_Weights
import timm

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
num_classes = 98

# --- ResNet50 ---
resnet = resnet50(weights=ResNet50_Weights.IMAGENET1K_V2)
resnet.fc = nn.Sequential(
    nn.Linear(resnet.fc.in_features, 512),
    nn.ReLU(),
    nn.Dropout(0.5),
    nn.Linear(512, num_classes)
)
resnet.load_state_dict(torch.load("model/ResNet50.pth", map_location=device))
resnet.eval().to(device)
print("___load model ResNet___")
# --- Vision Transformer ---
# vit = timm.create_model('vit_base_patch16_224', pretrained=True)
# vit.head = nn.Sequential(
#     nn.Linear(vit.head.in_features, 512),
#     nn.ReLU(),
#     nn.Dropout(0.5),
#     nn.Linear(512, num_classes)
# )
# vit.load_state_dict(torch.load("model/ViT_B_16.pth", map_location=device))
# vit.eval().to(device)
# print("___load model VIT___")
# # --- EfficientNet-B6 ---
# effnet = efficientnet_b6(weights=EfficientNet_B6_Weights.IMAGENET1K_V1)
# in_features = effnet.classifier[1].in_features
# effnet.classifier = nn.Sequential(
#     nn.Linear(in_features, 512),
#     nn.ReLU(),
#     nn.Dropout(0.5),
#     nn.Linear(512, num_classes)
# )
# effnet.load_state_dict(torch.load("model/EfficientNet_B6.pth", map_location=device))
# effnet.eval().to(device)
# print("___load model EfficientNet___")
models = [resnet]
