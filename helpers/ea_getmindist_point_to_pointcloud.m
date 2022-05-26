function Dist=ea_getmindist_point_to_pointcloud(points,pointcloud)

Dist=zeros(size(points,1),1);
for p_i=1:numel(Dist)
    Dist(p_i)=min(sum((points(p_i,:)-pointcloud).^2,2));
end
Dist=sqrt(Dist);