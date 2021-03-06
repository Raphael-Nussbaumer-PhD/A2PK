%% Creation of the Synthetic Data
% This section gather all possible way to create the data. |gen| struct
% store the parameter and |data_generation.m| compute everything

clc; clear all; addpath('../functions','R2'); dbstop if error 

% Grid size
gen.xmax = 50; %total length in unit [m]
gen.ymax = 30; %total hight in unit [m]

% Scale define the subdivision of the grid (multigrid). At each scale, the
% grid size is $(2^gen.sx+1) \times (2^gen.sy+1)$ 
gen.nx = gen.xmax*2+1;
gen.ny = gen.ymax*2+1;

% Generation parameter
gen.samp                = 1;          % Method of sampling of K and g | 1: borehole, 2:random. For fromK or from Rho only
gen.samp_n              = 0;          % number of well or number of point
gen.covar(1).model      = 'matern';
gen.covar(1).alpha      = 0.5;
gen.covar(1).range0     = [4 16]; 
gen.covar(1).azimuth    = 0;
gen.covar(1).c0         = 1;
gen.covar               = kriginginitiaite(gen.covar);
gen.mu                  = 0.25;%0.27; % parameter of the first field. 
gen.std                 = 0.05;%.05;

% Electrical inversion
gen.Rho.f ={};
gen.Rho.f.res_matrix    = 0;
gen.Rho.elec.spacing_y  = 1; % in unit [m] | adapted to fit the fine grid
gen.Rho.elec.bufzone_y  = 2; % number of electrod to skip 
gen.Rho.elec.x_t        = 25; % in unit [m] | adapted to fit the fine grid
gen.Rho.elec.x_r        = [10 40]; % in unit [m] | adapted to fit the fine grid
% gen.Rho.elec.x_t        = 10; % in unit [m] | adapted to fit the fine grid
% gen.Rho.elec.x_r        = [11 12 15 20 25 30 40]; % in unit [m] | adapted to fit the fine grid
gen.Rho.elec.config_max = 6000; % number of configuration of electrode maximal 
gen.Rho.i.grid.nx       = (gen.nx-1)/2+1; % | adapted to fit the fine grid
gen.Rho.i.grid.ny       = (gen.ny-1)/2+1; % log-spaced grid  | adapted to fit the fine grid
gen.Rho.i.res_matrix    = 3; % resolution matrix: 1-'sensitivity' matrix, 2-true resolution matrix or 0-none

% Other parameter
gen.plotit              = true;      % display graphic or not (you can still display later with |script_plot.m|)
gen.saveit              = true;       % save the generated file or not, this will be turn off if mehod Paolo or filename are selected
gen.name                = '60x20';
gen.seed                = 11;

% Run the function
fieldname = data_generation(gen);
%[fieldname, grid_gen, K_true, phi_true, sigma_true, K, sigma, Sigma, gen] = data_generation(gen);




%% Reproducing Theim equation
gen.xmax = 100; %total length in unit [m]
gen.ymax = 100; %total hight in unit [m]
gen.nx = gen.xmax*2+1;
gen.ny = gen.ymax*2+1;

% Generation parameter
gen.covar(1).model      = 'matern';
gen.covar(1).alpha      = 0.5;
gen.covar(1).range0     = [4 16]; 
gen.covar(1).azimuth    = 0;
gen.covar(1).c0         = 1;
gen.covar               = kriginginitiaite(gen.covar);
gen.mu                  = (log10(10^-5)+4.97)/6.66;
gen.std                 = 0;

% Electrical inversion
gen.Rho.f ={};
gen.Rho.f.res_matrix    = 0;
gen.Rho.elec.spacing_y  = 1; % in unit [m] | adapted to fit the fine grid
gen.Rho.elec.bufzone_y  = 30; % number of electrod to skip 
gen.Rho.elec.x_t        = 50; % in unit [m] | adapted to fit the fine grid
gen.Rho.elec.x_r        = [51 52 55 60 75 90 100]; % in unit [m] | adapted to fit the fine grid
gen.Rho.elec.config_max = 6000; % number of configuration of electrode maximal 
gen.Rho.i.grid.nx       = (gen.nx-1)/2+1; % | adapted to fit the fine grid
gen.Rho.i.grid.ny       = (gen.ny-1)/2+1; % log-spaced grid  | adapted to fit the fine grid
gen.Rho.i.res_matrix    = 3;

% Other parameter
gen.forwardonly         = 1;
gen.plotit              = true;      % display graphic or not (you can still display later with |script_plot.m|)
gen.saveit              = true;       % save the generated file or not, this will be turn off if mehod Paolo or filename are selected
gen.name                = '100x100';
gen.seed                = 11;

% Run the function
fieldname = data_generation(gen);

% Uniform K, 1 pumping well and 3 measuring well separated by 10 m each.
load('result/FOR-100x100_2018-04-04_14-23.mat')

% Thiem equation
% 
% $$h_{2}-h_{1}={\frac {Q}{2\pi b K}}\ln \left({\frac {r_{1}}{r_{2}}}\right)$$
% 

uex = unique(gen.Rho.elec.X(gen.Rho.elec.data(:,1)));
id = bsxfun(@eq,gen.Rho.elec.X(gen.Rho.elec.data(:,1))',uex );
h = id* gen.Rho.f.output.resistance./sum(id,2); 
dh = bsxfun(@minus,h',h);

Q=1;
b=gen.ymax;
K=mean(K_true(:));
r=abs(gen.Rho.elec.x_r-gen.Rho.elec.x_t);
dr = bsxfun(@rdivide,r',r);

disp(-Q/(2*pi*b*K).*log(dr))
disp(dh)
disp(-(dh+Q/(2*pi*b*K).*log(dr))./(Q/(2*pi*b*K).*log(dr))*100)


% Point-source injection
%
% $$ Q =4\pi^2 K \frac{\partial h}{\partial r}$$
% $$h_{2}-h_{1}={\frac {Q}{4\pi K}}\ln \left({\frac {1}{r_{2}} - \frac {1}{r_{1}}}\right)$$


[~,id0] = min((gen.Rho.elec.Y(gen.Rho.elec.data(:,3))-50).^2);
id = gen.Rho.elec.Y(gen.Rho.elec.data(:,3))==gen.Rho.elec.Y(gen.Rho.elec.data(id0,3));
h = gen.Rho.f.output.resistance(id);

x=gen.Rho.elec.X(gen.Rho.elec.data(id,1));
y=gen.Rho.elec.Y(gen.Rho.elec.data(id,1));
x0=gen.Rho.elec.X(gen.Rho.elec.data(id0,3));
y0=gen.Rho.elec.Y(gen.Rho.elec.data(id0,3));

figure(2); hold on;
scatter(x, y,[],log(h),'filled')
plot(x0,y0,'xk')
rectangle('Position',[0 0 gen.xmax gen.ymax])


Q=1;
K=mean(K_true(:));
r=sqrt( (x-x0).^2 + (y-y0).^2 );

theim = @(Q,K,hmax,r) -Q/(4*pi*K).*(1./Inf-1./r) + hmax;

rmse = @(x) sqrt( sum( ( theim(Q,K,x,r) - h ).^2 ) );
h0 = fminsearch(rmse,min(h));


figure; hold on;
scatter3(x,y,h,'.')
scatter3(x,y,theim(Q,K,h0,r),'.')
rectangle('Position',[0 0 gen.xmax gen.ymax]); view(3)


R = sqrt( (grid_gen.X-x0).^2 + (grid_gen.Y-y0).^2 );

figure; hold on;
s=surf(grid_gen.X, grid_gen.Y, theim(Q,K,h0,R));
scatter3(x,y,h,'.k')
s.EdgeColor='none';
set(gca,'zscale','log')
xlabel('X [m]'); ylabel('Y [m]'); zlabel('Head [log-m]');
legend({'Analytical solution','Observations'})





%% Testing other geostat param

fieldname='GEN-60x20_2018-03-13_14-26';
load(['result/' fieldname '.mat'])
addpath('../functions','R2');

% Normal Score based on known distribution of Prim and Sec
Nscore.forward = @(x) ( (log10(x)+4.97)./6.66 - gen.mu)./gen.std;
Nscore.inverse = @(x) 10.^(6.66*(x.*gen.std+gen.mu)-4.97); 
Sec=K; 
Sec.d = Nscore.forward(Sec.d);
Prim.d = Nscore.forward(K_true);
Prim.x = grid_gen.x; Prim.y = grid_gen.y; Prim.X = grid_gen.X; Prim.Y = grid_gen.Y;

% Built the matrix G which link the true variable Prim.d to the measured coarse scale d
G = zeros(numel(Sec.d), numel(Prim.d));
for i=1:numel(Sec.d)
    Res = reshape(Sec.res(i,:)+Sec.res_out(i)/numel(Sec.res(i,:)),numel(Sec.y),numel(Sec.x));
    f = griddedInterpolant({Sec.y,Sec.x},Res,'linear');
    res_t = f({Prim.y,Prim.x});
    G(i,:) = res_t(:) ./sum(res_t(:));
end


covar = gen.covar;
covar.range0 = covar.range0/2;
covar.alpha = covar.alpha/2;
covar = kriginginitiaite(covar);

plot(Prim.x,1-covar.g(Prim.x*covar.cx(1)))
xlim([0 50])

% Compute the weightings matrix
W = covar2W(covar,Prim,Sec,G,Prim_pt,Cmt);

% save(['result/' fieldname '_cond_covar_rx2'],'W','Prim_pt','G','Nscore','Sec','Prim','covar')
save(['result/' fieldname '_cond'],'W','Prim_pt','G','Nscore','Sec','Prim','covar')


% Load all files
listing = dir(['result/' fieldname '_cond*']);

parm.n_real = 30;
err=nan(numel(listing),parm.n_real);

for i_l = 1:numel(listing)
    
    % Load
    load([listing(i_l).folder '\' listing(i_l).name]);
    Nscore.inverse = @(x) 10.^(6.66*(x.*gen.std+gen.mu)-4.97);
    
    % Compute the Kriging map
    zh = reshape( W * [Sec.d(:) ; Prim_pt.d], numel(Prim.y), numel(Prim.x));

    % Compute the Realizations
    zcs=nan(numel(Prim.y), numel(Prim.x),parm.n_real);
    z=nan(numel(Sec.y), numel(Sec.x),parm.n_real);
    for i_real=1:parm.n_real
        zs = fftma_perso(covar, struct('x',Prim.x,'y',Prim.y));
        zhs = W * [G * zs(:) ; zs(Prim_pt.id)./1.3];
        r = zh(:) + (zs(:) - zhs(:));
        zcs(:,:,i_real) = reshape( r, numel(Prim.y), numel(Prim.x));
        z(:,:,i_real)=reshape(G*r(:), numel(Sec.y), numel(Sec.x) );
    end
    
    % Compute the Vario & Histo
    vario_x=nan(parm.n_real,numel(Prim.x));
    vario_y=nan(parm.n_real,numel(Prim.y));
    xi = -3:.1:3;
    f=nan(parm.n_real,numel(xi));
    for i_real=1:parm.n_real
        r = zcs(:,:,i_real);
        %r = (r(:)-mean(r(:)))./std(r(:));
        [vario_x(i_real,:),vario_y(i_real,:)]=variogram_gridded_perso(reshape( r(:), numel(Prim.y), numel(Prim.x)));
        
        r=zcs(:,:,i_real);
        f(i_real,:) = ksdensity(r(:),xi);
    end
    [vario_prim_x,vario_prim_y]=variogram_gridded_perso(Prim.d);


    % Compute the forward response
    fsim_pseudo=nan(numel(gen.Rho.f.output.pseudo),parm.n_real);
    fsim_resistance=nan(numel(gen.Rho.f.output.resistance),parm.n_real);
    rho = 1./Nscore.inverse(zcs);
    parfor i_real=1:parm.n_real
        f={};
        f.res_matrix        = gen.Rho.f.res_matrix;
        f.grid              = gen.Rho.f.grid;    
        f.header            = 'Forward';  % title of up to 80 characters
        f.job_type          = 0;
        f.filepath          = ['data_gen/IO-file-' num2str(i_real) '/'];
        f.readonly          = 0;
        f.alpha_aniso       = gen.Rho.f.alpha_aniso;
        f.elec_X_id         = gen.Rho.f.elec_X_id;
        f.elec_Y_id         = gen.Rho.f.elec_Y_id;
        f.rho               = rho(:,:,i_real);
        f.num_regions       = gen.Rho.f.num_regions;
        f.rho_min           = gen.Rho.f.rho_min;
        f.rho_avg           = gen.Rho.f.rho_avg;
        f.rho_max           = gen.Rho.f.rho_max;

        mkdir(f.filepath)
        f                   = Matlat2R2(f,gen.Rho.elec); % write file and run forward modeling
        fsim_pseudo(:,i_real) = f.output.pseudo;
        fsim_resistance(:,i_real) = f.output.resistance;
    end

    % Compute the misfit
    fsim_misfit=nan(numel(gen.Rho.f.output.resistancewitherror),parm.n_real);
    for i_real=1:parm.n_real  
        fsim_misfit(:,i_real) = (fsim_resistance(:,i_real) - gen.Rho.f.output.resistancewitherror) ./ (gen.Rho.i.a_wgt + gen.Rho.i.b_wgt*gen.Rho.f.output.resistancewitherror);
        err(i_l, i_real) = sqrt(mean(fsim_misfit(:,i_real).^2));
    end

end


figure; boxplot(err','Labels', {listing.name},'LabelOrientation','inline')





%% GW

kn=numel(K_true);

%hydraulic conductivity
k=[(1:kn)' ones(kn,1)*0.1 K_true(:) zeros(kn,1) K_true(:) zeros(kn,2) K_true(:) ones(kn,1)*0.1e-5];
dlmwrite('k.dat',k,'delimiter',' ','precision','%6.12f');

%mass properties
mp=[(1:kn)' ones(kn,1)*-4 ones(kn,1) ones(kn,1)*0.1 zeros(kn,1) ones(kn,1)*2e-9 zeros(kn,2) zeros(kn,1)];
dlmwrite('mp.dat',mp,'delimiter',' ','precision','%6.12f');

% run gw
!gw3.1.6_Win32.exe







%% ------------------------------------------------------------------------
% Previous Script
%--------------------------------------------------------------------------




%% Simulation of the Area-to-point Kriging 
rng('shuffle');

parm.n_real = 30;
% covar = kriginginitiaite(gen.covar);
zcs=nan(numel(Prim.y), numel(Prim.x),parm.n_real);
z=nan(numel(Sec.y), numel(Sec.x),parm.n_real);
for i_real=1:parm.n_real
    zs = fftma_perso(covar, struct('x',Prim.x,'y',Prim.y));
    %zs = fftma_perso(gen.covar, grid_gen);
    zhs = W * [G * zs(:) ; zs(Prim_pt.id)./1.3];
    r = zh(:) + (zs(:) - zhs(:));
    zcs(:,:,i_real) = reshape( r, numel(Prim.y), numel(Prim.x));
    z(:,:,i_real)=reshape(G*r(:), numel(Sec.y), numel(Sec.x) );
end

% Figure
figure(6);clf; colormap(viridis())
c_axis=[ -3 3];
subplot(4,1,1);surf(Prim.x, Prim.y, Prim.d,'EdgeColor','none','facecolor','flat'); caxis(c_axis);view(2); axis tight equal; set(gca,'Ydir','reverse'); colorbar;
% hold on; scatter(Prim_pt.x,Prim_pt.y,'filled','r')
subplot(4,1,2);surf(Prim.x, Prim.y, zcs(:,:,1),'EdgeColor','none','facecolor','flat'); caxis(c_axis);view(2); axis tight equal; set(gca,'Ydir','reverse'); 
subplot(4,1,3);surf(Prim.x, Prim.y, mean(zcs,3),'EdgeColor','none','facecolor','flat'); caxis(c_axis);view(2); axis tight equal; set(gca,'Ydir','reverse'); 
subplot(4,1,4);surf(Prim.x, Prim.y, std(zcs,[],3),'EdgeColor','none','facecolor','flat'); view(2); axis tight equal; set(gca,'Ydir','reverse'); colorbar;
%export_fig -eps 'PrimOverview'

figure;clf; colormap(viridis())
c_axis=[ -3 3];
subplot(4,1,1);surf(Prim.x, Prim.y, Prim.d,'EdgeColor','none','facecolor','flat'); caxis(c_axis);view(2); axis tight equal; set(gca,'Ydir','reverse');
% hold on; scatter(Prim_pt.x,Prim_pt.y,'filled','r')
subplot(4,1,2);surf(Prim.x, Prim.y, zcs(:,:,1),'EdgeColor','none','facecolor','flat'); caxis(c_axis);view(2); axis tight equal; set(gca,'Ydir','reverse'); 
subplot(4,1,3);surf(Prim.x, Prim.y, zcs(:,:,2),'EdgeColor','none','facecolor','flat'); caxis(c_axis);view(2); axis tight equal; set(gca,'Ydir','reverse'); 
subplot(4,1,4);surf(Prim.x, Prim.y, zcs(:,:,3),'EdgeColor','none','facecolor','flat'); caxis(c_axis);view(2); axis tight equal; set(gca,'Ydir','reverse'); 
%export_fig -eps 'PrimOverview'

figure(7);clf; colormap(viridis())
c_axis=[ -3 3];
subplot(4,1,1);surf(Sec.x, Sec.y, Sec.d,'EdgeColor','none','facecolor','flat'); caxis(c_axis); view(2); axis tight equal; set(gca,'Ydir','reverse');  colorbar;
subplot(4,1,2);surf(Sec.x, Sec.y, z(:,:,1),'EdgeColor','none','facecolor','flat'); caxis(c_axis); view(2); axis tight equal; set(gca,'Ydir','reverse'); 
subplot(4,1,3);surf(Sec.x, Sec.y, mean(z,3),'EdgeColor','none','facecolor','flat'); caxis(c_axis); view(2); axis tight equal; set(gca,'Ydir','reverse');
subplot(4,1,4);surf(Sec.x, Sec.y, std(z,[],3),'EdgeColor','none','facecolor','flat');  title('d Average of True field');view(2); axis tight equal; set(gca,'Ydir','reverse'); colorbar;
%export_fig -eps 'SecOverview'

figure;clf; colormap(viridis())
c_axis=[ -1 1];
subplot(4,1,1);surf(Sec.x, Sec.y, Sec.d,'EdgeColor','none','facecolor','flat'); caxis(c_axis); view(2); axis tight equal; set(gca,'Ydir','reverse');
subplot(4,1,2);surf(Sec.x, Sec.y, z(:,:,1),'EdgeColor','none','facecolor','flat'); caxis(c_axis); view(2); axis tight equal; set(gca,'Ydir','reverse'); 
subplot(4,1,3);surf(Sec.x, Sec.y, z(:,:,2),'EdgeColor','none','facecolor','flat'); caxis(c_axis); view(2); axis tight equal; set(gca,'Ydir','reverse');
subplot(4,1,4);surf(Sec.x, Sec.y, z(:,:,3),'EdgeColor','none','facecolor','flat'); caxis(c_axis); view(2); axis tight equal; set(gca,'Ydir','reverse'); 
%export_fig -eps 'SecOverview'

figure(8);clf;colormap(viridis())
subplot(2,1,1);surface(Sec.X,Sec.Y,Test_Sec_d-Sec.d,'EdgeColor','none','facecolor','flat'); view(2); set(gca,'Ydir','reverse');  axis equal tight; box on; xlabel('x');ylabel('y'); caxis([-.6 .6]);colorbar('southoutside');
subplot(2,1,2);surf(Sec.x, Sec.y, mean(z,3)-Sec.d,'EdgeColor','none','facecolor','flat'); view(2); axis tight equal; set(gca,'Ydir','reverse'); colorbar('southoutside');caxis([-.6 .6])
%export_fig -eps 'GztrueGzsim'

% Compute the Variogram and Histogram of realiaztions
parm.n_real=500;
vario_x=nan(parm.n_real,nx);
vario_y=nan(parm.n_real,ny);
for i_real=1:parm.n_real
    r = zcs(:,:,i_real);
    %r = (r(:)-mean(r(:)))./std(r(:));
    [vario_x(i_real,:),vario_y(i_real,:)]=variogram_gridded_perso(reshape( r(:), ny, nx));
end
[vario_prim_x,vario_prim_y]=variogram_gridded_perso(Prim.d);

figure(9);clf;
subplot(2,1,1);  hold on; 
h1=plot(Prim.x(1:2:end),vario_x(:,1:2:end)','b','color',[.5 .5 .5]);
h2=plot(Prim.x,vario_prim_x,'-r','linewidth',2);
h3=plot(Prim.x,1-covar.g(Prim.x*covar.cx(1)),'--k','linewidth',2);
xlim([0 30]); xlabel('Lag-distance h_x ');ylabel('Variogram \gamma(h_x)')
legend([h1(1) h2 h3],'500 realizations','True field','Theorical Model')
subplot(2,1,2); hold on; 
h1=plot(Prim.y,vario_y','b','color',[.5 .5 .5]);
h2=plot(Prim.y,vario_prim_y,'-r','linewidth',2);
h3=plot(Prim.y,1-covar.g(Prim.y*covar.cx(4)),'--k','linewidth',2);
xlim([0 6]); xlabel('Lag-distance h_y ');ylabel('Variogram \gamma(h_y)')
legend([h1(1) h2 h3],'500 realizations','True field','Theorical Model')
% export_fig -eps 'Vario'


figure(10);clf; hold on; colormap(viridis())
for i_real=1:parm.n_real
    r=zcs(:,:,i_real);
    %r = (r(:)-mean(r(:)))./std(r(:));
    [f,xi] = ksdensity(r(:));
    h1=plot(xi,f,'b','color',[.5 .5 .5]);
end
[f,xi] = ksdensity(Prim.d(:));
h4=plot(xi,f,'-r','linewidth',2);
[f,xi] = ksdensity(Prim_pt.d(:));
h2=plot(xi,f,'-g','linewidth',2);
h3=plot(xi,normpdf(xi),'--k','linewidth',2);
xlabel('Lag-distance h ');ylabel('Variogram \gamma(h)')
legend([h1 h2 h3 h4],'500 realizations','True field','Theorical Model','Sampled value (well)')
% export_fig -eps 'Histogram'



%% Forward simulation
% Put the realization in the forward ERT

parm.n_real=500;
fsim_pseudo=nan(numel(gen.Rho.f.output.pseudo),parm.n_real);
fsim_resistance=nan(numel(gen.Rho.f.output.resistance),parm.n_real);
rho = 1000./Nscore.inverse(zcs);
for i_real=1:parm.n_real
    f={};
    f.res_matrix        = gen.Rho.f.res_matrix;
    f.grid              = gen.Rho.f.grid;    
    f.header            = 'Forward';  % title of up to 80 characters
    f.job_type          = 0;
    f.filepath          = ['data_gen/IO-file-' num2str(i_real) '/'];
    f.readonly          = 0;
    f.alpha_aniso       = gen.Rho.f.alpha_aniso;
    f.elec_spacing      = gen.Rho.f.elec_spacing;
    f.elec_id           = gen.Rho.f.elec_id;
    f.rho               = rho(:,:,i_real);
    f.num_regions       = gen.Rho.f.num_regions;
    f.rho_min           = gen.Rho.f.rho_min;
    f.rho_avg           = gen.Rho.f.rho_avg;
    f.rho_max           = gen.Rho.f.rho_max;
    
    mkdir(f.filepath)
    f                   = Matlat2R2(f,gen.Rho.elec); % write file and run forward modeling
    fsim_pseudo(:,i_real) = f.output.pseudo;
    fsim_resistance(:,i_real) = f.output.resistance;
end


% Compute the misfit
fsim_misfit=nan(numel(gen.Rho.f.output.resistancewitherror),parm.n_real);
err=nan(1,parm.n_real);
for i_real=1:parm.n_real  
    fsim_misfit(:,i_real) = (fsim_resistance(:,i_real) - gen.Rho.f.output.resistancewitherror) ./ (gen.Rho.i.a_wgt + gen.Rho.i.b_wgt*gen.Rho.f.output.resistancewitherror);
    err(i_real) = sqrt(mean(fsim_misfit(:,i_real).^2));
end
% export_fig -eps 'Histogram_of_misfit'
% save(['result/' fieldname '_sim'],'zcs','fsim_pseudo','fsim_resistance')


figure(11);
histogram(err);
xlabel('Misfit'); ylabel('Histogram')
% export_fig -eps 'misfit-hist'




figure(12);clf; colormap(viridis());c_axis=[min(gen.Rho.f.output.pseudo(:)) max(gen.Rho.f.output.pseudo(:))]; clf;
subplot(3,1,1); scatter(gen.Rho.f.pseudo_x,gen.Rho.f.pseudo_y,[],gen.Rho.f.output.pseudo,'filled');set(gca,'Ydir','reverse');caxis(c_axis);  xlim([0 100]); ylim([0 16]); colorbar('southoutside');
subplot(3,1,2); scatter(gen.Rho.f.pseudo_x,gen.Rho.f.pseudo_y,[],mean(fsim_pseudo,2),'filled');set(gca,'Ydir','reverse');caxis(c_axis); colorbar('southoutside');xlim([0 100]); ylim([0 16])
subplot(3,1,3); scatter(gen.Rho.f.pseudo_x,gen.Rho.f.pseudo_y,[],std(fsim_pseudo,[],2)./mean(fsim_pseudo,2),'filled');set(gca,'Ydir','reverse'); colorbar('southoutside');xlim([0 100]); ylim([0 16])
% export_fig -eps 'pseudo-sec'

figure(13);clf;colormap(viridis()); c_axis=[min(gen.Rho.f.output.pseudo(:)) max(gen.Rho.f.output.pseudo(:))]; clf;
subplot(3,1,1); scatter(gen.Rho.f.pseudo_x,gen.Rho.f.pseudo_y,[],(mean(fsim_pseudo,2)-gen.Rho.f.output.pseudo)./gen.Rho.f.output.pseudo,'filled');set(gca,'Ydir','reverse'); colorbar('southoutside');xlim([0 100]); ylim([0 16])
caxis([-.1 .1])
subplot(3,1,2); scatter(gen.Rho.f.pseudo_x,gen.Rho.f.pseudo_y,[],(gen.Rho.i.output.pseudo-gen.Rho.f.output.pseudo)./gen.Rho.f.output.pseudo,'filled');set(gca,'Ydir','reverse'); colorbar('southoutside');xlim([0 100]); ylim([0 16])
caxis([-.05 .05])
% export_fig -eps 'pseudo-sec-err'

figure(23); clf; hold on; axis equal tight;
for i_real=1:parm.n_real  
    scatter(fsim_pseudo(:,i_real),gen.Rho.f.output.pseudo,'.k');
end
scatter(gen.Rho.i.output.pseudo,gen.Rho.f.output.pseudo,'.r');
scatter(mean(fsim_pseudo,2),gen.Rho.f.output.pseudo,'.g');
x=[floor(min(fsim_pseudo(:))) ceil(max(fsim_pseudo(:)))];
plot(x,x,'-r'); 
plot(x,x-x*3*gen.Rho.i.b_wgt,'--r'); 
plot(x,x+x*3*gen.Rho.i.b_wgt,'--r'); 
xlabel('Apparent resistivity measured from simulated fields');
ylabel('Apparent resistivity measured from true fields');
set(gca, 'YScale', 'log'); set(gca, 'XScale', 'log')
% export_fig -eps 'pseudo-sec-err'

   

%% Figure for Synthetic schema
   
figure(199);clf; n=5;
subplot(n,1,1);imagesc(grid_gen.x, grid_gen.y, phi_true); axis tight; colormap(viridis());daspect([2 1 1])
subplot(n,1,2);imagesc(grid_gen.x, grid_gen.y, sigma_true); axis tight equal; colormap(viridis()); daspect([2 1 1])
subplot(n,1,3);scatter(gen.Rho.i.pseudo_x,gen.Rho.i.pseudo_y,[], gen.Rho.i.output.pseudo,'filled'); colormap(viridis());set(gca,'Ydir','reverse'); xlim([0 100]);ylim([0 20]);daspect([2 1 1])
subplot(n,1,4); surface(Sec.x, Sec.y, Sigma.d,'EdgeColor','none','facecolor','flat'); axis tight; colormap(viridis());set(gca,'Ydir','reverse');daspect([2 1 1])
subplot(n,1,5); imagesc(log(abs(Sigma.res))); axis equal tight; colormap(viridis());
