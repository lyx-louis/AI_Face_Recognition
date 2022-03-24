% P. Vallet (Bordeaux INP), 2019

clc;
clear all;
close all;

%% Data extraction
% Training set
adr = './database/training1/';
fld = dir(adr);
nb_elt = length(fld);
% Data matrix containing the training images in its columns 
data_trn = []; 
% Vector containing the class of each training image
lb_trn = []; 
for i=1:nb_elt
    if fld(i).isdir == false
        lb_trn = [lb_trn ; str2num(fld(i).name(6:7))]; % ex: yaleB ' 01 '
        img = double(imread([adr fld(i).name]));
        data_trn = [data_trn img(:)]; % 将 每个192*168的文件读取成32256 的数字， 然后存储, 总共60个文件
    end
end
% Size of the training set
[P,N] = size(data_trn);
% Classes contained in the training set
[~,I]=sort(lb_trn);
data_trn = data_trn(:,I); % 
[cls_trn,bd,~] = unique(lb_trn); % 
Nc = length(cls_trn); 
% Number of training images in each class
size_cls_trn = [bd(2:Nc)-bd(1:Nc-1);N-bd(Nc)+1];  % 每类图片有多少个

% mean_face_ligne = mean(data_trn,2);
% mean_face = reshape(mean_face_ligne,192,168);
% Image_mean=mat2gray(mean_face);
% imwrite(Image_mean,'meanface.bmp','bmp');
% figure,
% imagesc(mean_face);
% colormap(gray);

% centraliser
% X = [];
% for i = 1:60
%     X(:,i) = (data_trn(:,i) - mean_face_ligne)/sqrt(60); % (p * n ) avec p = 32256, n = 60 = > X
% end

% meme resultat, plus simple pour matlab qu'une boucle for
X_mean_emp = 1/N * sum(data_trn,2); % mean_face_ligne
X_centered = data_trn - X_mean_emp;
X = 1/sqrt(N) * X_centered;

% R = X * X'; % 32256*32256 ==> je la commente, mon pc meurt en la
% calculant

R_gram = X' * X; % 60 * 60
% [eigenvector,eigenvalue]=eigs(R,60);
[eigenvector,eigenvalue]=eigs(R_gram,length(R_gram));
U = X * eigenvector * (eigenvector'*X'*X*eigenvector)^(-0.5); % 特征脸 eigenface

U = real(U); % pour Matlab R2021b


figure(1)
sgtitle("The 60 eigenvectors of U"); % Peut ne pas fonctionner si Matlab < R2018b
% affichage des eigenfaces
for i = 1:length(R_gram)
    subplot(6,length(R_gram)/6,i);
    imagesc(U(:,i));
    colormap(gray);
end

figure(2)
sgtitle("Reshaped eigenfaces");
for i = 1:length(R_gram)
    subplot(6,length(R_gram)/6,i);
    img = U(:,i);
    img = reshape(img,192,168);
    imagesc(img);
    colormap(gray);
end
%% RECONSTRUCTION DES IMAGES

l_values=[2,10,20,30,40,50]; % dimension du facespace, l <= n % 投影的维度
l_values=[2,5,10,15, 20, 25]; % pour 30
    imgs  = zeros(P,36);
imgsM = zeros(P,36);

for loop=1:36
    idx = bd(ceil(loop/6));
    [img, imgM]   = eigenfaces_builder(data_trn(:,idx), U, l_values(mod(loop-1,6)+1), X_mean_emp);
    imgs(:,loop)  = img;
    imgsM(:,loop) = imgM;
    imgvalue(:,loop) = imgs(:,loop)'*imgs(:,loop);
    imgvalue_original(:,loop) = data_trn(:,idx)'*data_trn(:,idx);
end

ratio = imgvalue./imgvalue_original;


imgs = reshape_imgs(imgs, 6,6);
imgsM = reshape_imgs(imgsM,6,6);

% display
f = figure(3);
imagesc(imgs);
% Changement d'axes
ax = get(f,'Children'); % on extrait l'objet Axis de la figure

% intervalles de ticks pour qu'ils soient centres
Xticks = 84:168:1008;
Yticks = 96:192:1152;

% on change les ticks sur les axes X et Y
ax.XTick = Xticks;
ax.YTick = Yticks;

% On extrait les objets NumericRulers qui correspondent aux axes
XA = get(ax,'XAxis');
YA = get(ax,'YAxis');

% On change le texte affiche sur l'axe pour les valeurs souhaitees
XA.TickLabels = l_values;
YA.TickLabels = cls_trn;

colormap(gray);
title("Reconstruction test");
ylabel("Class of the image");
xlabel("Dimension of the facespace");

% display
f = figure(4);
imagesc(imgsM);

% Changement d'axes
ax = get(f,'Children'); % on extrait l'objet Axis de la figure

% on change les ticks sur les axes X et Y
ax.XTick = Xticks;
ax.YTick = Yticks;

% On extrait les objets NumericRulers qui correspondent aux axes
XA = get(ax,'XAxis');
YA = get(ax,'YAxis');

% On change le texte affiche sur l'axe pour les valeurs souhaitees
XA.TickLabels = l_values;
YA.TickLabels = cls_trn;

colormap(gray);
title("Reconstruction test with recentering");
ylabel("Class of the image");
xlabel("Dimension of the facespace");

%% ratio de l'energie de projection



%%
% img = reshape(img,192,168); % imagesc can't reshape automatically, strange
% fprintf("Generated image with idx=%d and l_value=%d\n",idx,l_values(mod(loop-1,6)+1));
% 
% imagesc(img); colormap(gray);
    



% 
% l = 10; % 低维 % 对6个不同的图像进行低维投射
% recons = [];
% UL = U(:,1:10);



% for i = 1:60
%     for j = 1:l
%         recons(:,i) = recons(:,i) + U(:,j)'*X(:,i)*U(:,j);
%     end
% end
% % recons = recons + mean_face_ligne;
% % recons_schema = reshape(recons,192,168);
% % figure,
% % subplot(321);
% % imagesc(recons_schema);
% % colormap(gray)
% % 
% % subplot(322)
% % image_fisrt = reshape(data_trn(:,1),192,168);
% % imagesc(image_fisrt);
% % colormap(gray);
% % 



    


%Display the database
% F = zeros(192*Nc,168*max(size_cls_trn));
% for i=1:Nc
%     for j=1:size_cls_trn(i)
%           pos = sum(size_cls_trn(1:i-1))+j;
%           F(192*(i-1)+1:192*i,168*(j-1)+1:168*j) = reshape(data_trn(:,pos),[192,168]);
%     end
% end
% figure;
% imagesc(F);
% colormap(gray);
% axis off;