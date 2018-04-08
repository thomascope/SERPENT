SPM = load('SPM.mat')
SPM = SPM.SPM
SPM.Sess
SPM.Sess(1)
SPM.Sess(2)
X = SPM.xX.X(SPM.Sess(1).row,SPM.Sess(1).col);
figure
imagesc(X)
SPM.Sess(1)
SPM.Sess(1).U
[SPM.Sess(1).U.name]
[SPM.Sess(1).U.name]'
imagesc(X(:,1:96))
imagesc(X(:,1:98))
v = diag(inv(corrcoef(X)));
v
names = [SPM.Sess(1).U.name]
figure
plot(v)
v = diag(inv(corrcoef(X(:,1:98))));
plot(v)
% v = diag(inv(corrcoef(X(:,1:98))),'o-');
% plot(v,'o-')
% test = ans;
% figure
% imagesc(test(1:98,1:98))
% SPM
% SPM = SPM.SPM
% SPM = load('SPM.mat')
% SPM = SPM.SPM
% X = SPM.xX.X(SPM.Sess(1).row,SPM.Sess(1).col);
% whos X
% v = diag(inv(corrcoef(X(:,1:98))));
% plot(v)
% figure
% plot(v)
% min(v)
% imagesc(X(:,1:98))
% X(:,all(X==0),2) = [];
% badind = all(X==0,2);
% whos badind
% sum(badind)
% badind = all(X<.1,2);
% sum(badind)
% SPM = load('SPM.mat')
% SPM = SPM.SPM
% X = SPM.xX.X(SPM.Sess(1).row,SPM.Sess(1).col);
% v = diag(inv(corrcoef(X(:,1:98))));
% figure
% plot(v)
% imagesc(X(:,1:98))
% plot(v)
% X
% imagesc(X(:,1:98))
% v = diag(inv(corrcoef(X(:,1:64))));
% plot(v)
% imagesc(X(:,1:98))
% ylim([0,10])
% X(:,[66,67,77,80]) = [];
% v = diag(inv(corrcoef(X(:,1:94))));
% plot(v)
% plot(v,'o-')
% v = diag(inv(corrcoef(X(:,1:93))));
% plot(v,'o-')