#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support. Compile with -fobjc-arc"
#endif

#define NUM_CUBE_VERTICES 108
#define NUM_CUBE_COLORS 144

#import "TreasureHuntRenderer.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#import "GVRHeadTransform.h"

// Vertex shader implementation.
static const char *kVertexShaderString =
    "#version 100\n"
    "\n"
    "uniform mat4 uMVP; \n"
    "uniform vec3 uPosition; \n"
    "attribute vec3 aVertex; \n"
    "attribute vec4 aColor;\n"
    "varying vec4 vColor;\n"
    "varying vec3 vGrid;  \n"
    "void main(void) { \n"
    "  vGrid = aVertex + uPosition; \n"
    "  vec4 pos = vec4(vGrid, 1.0); \n"
    "  vColor = aColor;"
    "  gl_Position = uMVP * pos; \n"
    "    \n"
    "}\n";

// Simple pass-through fragment shader.
static const char *kPassThroughFragmentShaderString =
    "#version 100\n"
    "\n"
    "#ifdef GL_ES\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec4 vColor;\n"
    "\n"
    "void main(void) { \n"
    "  gl_FragColor = vColor; \n"
    "}\n";

// Fragment shader for the floorplan grid.
// Line patters are generated based on the fragment's position in 3d.
static const char* kGridFragmentShaderString =
    "#version 100\n"
    "\n"
    "#ifdef GL_ES\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec4 vColor;\n"
    "varying vec3 vGrid;\n"
    "\n"
    "void main() {\n"
    "    float depth = gl_FragCoord.z / gl_FragCoord.w;\n"
    "    if ((mod(abs(vGrid.x), 10.0) < 0.1) ||\n"
    "        (mod(abs(vGrid.z), 10.0) < 0.1)) {\n"
    "      gl_FragColor = max(0.0, (90.0-depth) / 90.0) *\n"
    "                     vec4(1.0, 1.0, 1.0, 1.0) + \n"
    "                     min(1.0, depth / 90.0) * vColor;\n"
    "    } else {\n"
    "      gl_FragColor = vColor;\n"
    "    }\n"
    "}\n";

// Vertices for uniform cube mesh centered at the origin.
static const float kCubeVertices[NUM_CUBE_VERTICES] = {
  // Front face
  -0.5f, 0.5f, 0.5f,
  -0.5f, -0.5f, 0.5f,
  0.5f, 0.5f, 0.5f,
  -0.5f, -0.5f, 0.5f,
  0.5f, -0.5f, 0.5f,
  0.5f, 0.5f, 0.5f,
  // Right face
  0.5f, 0.5f, 0.5f,
  0.5f, -0.5f, 0.5f,
  0.5f, 0.5f, -0.5f,
  0.5f, -0.5f, 0.5f,
  0.5f, -0.5f, -0.5f,
  0.5f, 0.5f, -0.5f,
  // Back face
  0.5f, 0.5f, -0.5f,
  0.5f, -0.5f, -0.5f,
  -0.5f, 0.5f, -0.5f,
  0.5f, -0.5f, -0.5f,
  -0.5f, -0.5f, -0.5f,
  -0.5f, 0.5f, -0.5f,
  // Left face
  -0.5f, 0.5f, -0.5f,
  -0.5f, -0.5f, -0.5f,
  -0.5f, 0.5f, 0.5f,
  -0.5f, -0.5f, -0.5f,
  -0.5f, -0.5f, 0.5f,
  -0.5f, 0.5f, 0.5f,
  // Top face
  -0.5f, 0.5f, -0.5f,
  -0.5f, 0.5f, 0.5f,
  0.5f, 0.5f, -0.5f,
  -0.5f, 0.5f, 0.5f,
  0.5f, 0.5f, 0.5f,
  0.5f, 0.5f, -0.5f,
  // Bottom face
  0.5f, -0.5f, -0.5f,
  0.5f, -0.5f, 0.5f,
  -0.5f, -0.5f, -0.5f,
  0.5f, -0.5f, 0.5f,
  -0.5f, -0.5f, 0.5f,
  -0.5f, -0.5f, -0.5f,
};

// Color of the cube's six faces.
static const float kCubeColors[NUM_CUBE_COLORS] = {
  // front, green
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,

  // right, blue
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,

  // back, also green
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,
  0.0f, 0.5273f, 0.2656f, 1.0f,

  // left, also blue
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,

  // top, red
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,

  // bottom, also red
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
  0.8359375f, 0.17578125f, 0.125f, 1.0f,
};

// Cube color when looking at it: Yellow.
static const float kCubeFoundColors[NUM_CUBE_COLORS] = {
  // front, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // right, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // back, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // left, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // top, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,

  // bottom, yellow
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
  1.0f, 0.6523f, 0.0f, 1.0f,
};

// Cube size (scale).
static const float kCubeSize = 2.0f;

static GLuint LoadShader(GLenum type, const char *shader_src) {
  GLint compiled = 0;

  // Create the shader object
  const GLuint shader = glCreateShader(type);
  if (shader == 0) {
    return 0;
  }
  // Load the shader source
  glShaderSource(shader, 1, &shader_src, NULL);

  // Compile the shader
  glCompileShader(shader);
  // Check the compile status
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

  if (!compiled) {
    GLint info_len = 0;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &info_len);

    if (info_len > 1) {
      char *info_log = ((char *)malloc(sizeof(char) * info_len));
      glGetShaderInfoLog(shader, info_len, NULL, info_log);
      NSLog(@"Error compiling shader:%s", info_log);
      free(info_log);
    }
    glDeleteShader(shader);
    return 0;
  }
  return shader;
}

// Checks the link status of the given program.
static bool checkProgramLinkStatus(GLuint shader_program) {
  GLint linked = 0;
  glGetProgramiv(shader_program, GL_LINK_STATUS, &linked);

  if (!linked) {
    GLint info_len = 0;
    glGetProgramiv(shader_program, GL_INFO_LOG_LENGTH, &info_len);

    if (info_len > 1) {
      char *info_log = ((char *)malloc(sizeof(char) * info_len));
      glGetProgramInfoLog(shader_program, info_len, NULL, info_log);
      NSLog(@"Error linking program: %s", info_log);
      free(info_log);
    }
    glDeleteProgram(shader_program);
    return false;
  }
  return true;
}

@implementation TreasureHuntRenderer {
  // GL variables for the cube.
  GLfloat _cube_vertices[NUM_CUBE_VERTICES];
  GLfloat _cube_position[3];
  GLfloat _cube_colors[NUM_CUBE_COLORS];
  GLfloat _cube_found_colors[NUM_CUBE_COLORS];

  GLuint _cube_program;
  GLint _cube_vertex_attrib;
  GLint _cube_position_uniform;
  GLint _cube_mvp_matrix;
  GLuint _cube_vertex_buffer;
  GLint _cube_color_attrib;
  GLuint _cube_color_buffer;
  GLuint _cube_found_color_buffer;
}

#pragma mark - GVRCardboardViewDelegate overrides

- (void)cardboardView:(GVRCardboardView *)cardboardView
     willStartDrawing:(GVRHeadTransform *)headTransform {
  // Renderer must be created on GL thread before any call to drawFrame.
  // Load the vertex/fragment shaders.
  const GLuint vertex_shader = LoadShader(GL_VERTEX_SHADER, kVertexShaderString);
  NSAssert(vertex_shader != 0, @"Failed to load vertex shader");
  const GLuint fragment_shader = LoadShader(GL_FRAGMENT_SHADER, kPassThroughFragmentShaderString);
  NSAssert(fragment_shader != 0, @"Failed to load fragment shader");

  /////// Create the program object for the cube.

  _cube_program = glCreateProgram();
  NSAssert(_cube_program != 0, @"Failed to create program");
  glAttachShader(_cube_program, vertex_shader);
  glAttachShader(_cube_program, fragment_shader);

  // Link the shader program.
  glLinkProgram(_cube_program);
  NSAssert(checkProgramLinkStatus(_cube_program), @"Failed to link _cube_program");

  // Get the location of our attributes so we can bind data to them later.
  _cube_vertex_attrib = glGetAttribLocation(_cube_program, "aVertex");
  NSAssert(_cube_vertex_attrib != -1, @"glGetAttribLocation failed for aVertex");
  _cube_color_attrib = glGetAttribLocation(_cube_program, "aColor");
  NSAssert(_cube_color_attrib != -1, @"glGetAttribLocation failed for aColor");

  // After linking, fetch references to the uniforms in our shader.
  _cube_mvp_matrix = glGetUniformLocation(_cube_program, "uMVP");
  _cube_position_uniform = glGetUniformLocation(_cube_program, "uPosition");
  NSAssert(_cube_mvp_matrix != -1 && _cube_position_uniform != -1,
           @"Error fetching uniform values for shader.");
  // Initialize the vertex data for the cube mesh.
  for (int i = 0; i < NUM_CUBE_VERTICES; ++i) {
    _cube_vertices[i] = (GLfloat)(kCubeVertices[i] * kCubeSize);
  }
  glGenBuffers(1, &_cube_vertex_buffer);
  NSAssert(_cube_vertex_buffer != 0, @"glGenBuffers failed for vertex buffer");
  glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_vertices), _cube_vertices, GL_STATIC_DRAW);

  // Initialize the color data for the cube mesh.
  for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
    _cube_colors[i] = (GLfloat)(kCubeColors[i] * kCubeSize);
  }
  glGenBuffers(1, &_cube_color_buffer);
  NSAssert(_cube_color_buffer != 0, @"glGenBuffers failed for color buffer");
  glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_colors), _cube_colors, GL_STATIC_DRAW);

  // Initialize the found color data for the cube mesh.
  for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
    _cube_found_colors[i] = (GLfloat)(kCubeFoundColors[i] * kCubeSize);
  }
  glGenBuffers(1, &_cube_found_color_buffer);
  NSAssert(_cube_found_color_buffer != 0, @"glGenBuffers failed for color buffer");
  glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_found_colors), _cube_found_colors, GL_STATIC_DRAW);

  // Spawn the cube
  [self spawnCube];
}

- (void)cardboardView:(GVRCardboardView *)cardboardView
     prepareDrawFrame:(GVRHeadTransform *)headTransform {

  // Clear GL viewport.
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glEnable(GL_DEPTH_TEST);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glEnable(GL_SCISSOR_TEST);
}

- (void)cardboardView:(GVRCardboardView *)cardboardView
              drawEye:(GVREye)eye
    withHeadTransform:(GVRHeadTransform *)headTransform {
  CGRect viewport = [headTransform viewportForEye:eye];
  glViewport(viewport.origin.x, viewport.origin.y, viewport.size.width, viewport.size.height);
  glScissor(viewport.origin.x, viewport.origin.y, viewport.size.width, viewport.size.height);

  // Get the head matrix.
  const GLKMatrix4 head_from_start_matrix = [headTransform headPoseInStartSpace];

  // Get this eye's matrices.
  GLKMatrix4 projection_matrix = [headTransform projectionMatrixForEye:eye near:0.1f far:100.0f];
  GLKMatrix4 eye_from_head_matrix = [headTransform eyeFromHeadMatrix:eye];

  // Compute the model view projection matrix.
  GLKMatrix4 model_view_projection_matrix = GLKMatrix4Multiply(
      projection_matrix, GLKMatrix4Multiply(eye_from_head_matrix, head_from_start_matrix));

  // Render from this eye.
  [self renderWithModelViewProjectionMatrix:model_view_projection_matrix.m];
}

- (void)renderWithModelViewProjectionMatrix:(const float *)model_view_matrix {
  // Select our shader.
  glUseProgram(_cube_program);

  // Set the uniform values that will be used by our shader.
  glUniform3fv(_cube_position_uniform, 1, _cube_position);

  // Set the uniform matrix values that will be used by our shader.
  glUniformMatrix4fv(_cube_mvp_matrix, 1, false, model_view_matrix);

  // Set the cube colors.
  glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer);
  glVertexAttribPointer(_cube_color_attrib, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
  glEnableVertexAttribArray(_cube_color_attrib);

  // Draw our polygons.
  glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer);
  glVertexAttribPointer(_cube_vertex_attrib, 3, GL_FLOAT, GL_FALSE,
                        sizeof(float) * 3, 0);
  glEnableVertexAttribArray(_cube_vertex_attrib);
  glDrawArrays(GL_TRIANGLES, 0, NUM_CUBE_VERTICES / 3);
  glDisableVertexAttribArray(_cube_vertex_attrib);
}

- (void)cardboardView:(GVRCardboardView *)cardboardView
         didFireEvent:(GVRUserEvent)event {
  switch (event) {
    case kGVRUserEventBackButton:
      NSLog(@"User pressed back button");
      break;
    case kGVRUserEventTilt:
      NSLog(@"User performed tilt action");
      break;
    case kGVRUserEventTrigger:
      NSLog(@"User performed trigger action");
      break;
  }
}

- (void)cardboardView:(GVRCardboardView *)cardboardView shouldPauseDrawing:(BOOL)pause {
  if ([self.delegate respondsToSelector:@selector(shouldPauseRenderLoop:)]) {
    [self.delegate shouldPauseRenderLoop:pause];
  }
}

- (void)spawnCube {
  _cube_position[0] = 0;
  _cube_position[1] = 0.1;
  _cube_position[2] = 0;
}

// Returns whether the object is currently on focus.
//- (bool)isLookingAtObject:(const GLKQuaternion *)head_rotation
//           sourcePosition:(GLKVector3 *)position {
//  GLKVector3 source_direction = GLKQuaternionRotateVector3(
//      GLKQuaternionInvert(*head_rotation), *position);
//  return ABS(source_direction.v[0]) < kFocusThresholdRadians &&
//         ABS(source_direction.v[1]) < kFocusThresholdRadians;
//}

@end
