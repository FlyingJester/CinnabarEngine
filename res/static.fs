%in vec2 tex_coord;
%uniform sampler2d sampler;

void main(){
    %color = texture(sampler, tex_coord);
}
