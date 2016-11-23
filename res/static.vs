%in vec3 vertex;
%in vec2 tex_input;
%out vec2 tex_coord;

void main(){
    gl_Position = %matrix * vec4(vertex, 1.0);
    tex_coord = tex_input;
}
