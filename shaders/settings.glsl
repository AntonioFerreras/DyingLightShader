
//Survior sense
#define SURVIVOR_SENSE_ENABLED // Hold crouch and scan the environment for hostile mobs and players
// #define SURVIVOR_SENSE_ALWAYS_ACTIVE // Whether or not you have to crouch to enable surv sense
#define SURVIVOR_SENSE_R 0.788 // The red colour of the scanning effect when sneaking [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SURVIVOR_SENSE_G 0.96 // The green colour of the scanning effect when sneaking [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SURVIVOR_SENSE_B 1.0 // The blue colour of the scanning effect when sneaking [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SURVIVOR_SENSE_INTENSITY 0.2 // The brightness of the scanning pulse [0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

//Flashlight
#define FLASHLIGHT_TEMP 6200 // The temperature in Kelvin (K) of flashlight beam. Lower = Oranger, Higher = Bluer[3000 3500 4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000 5100 5200 5300 5400 5500 5600 5700 5800 5900 6000 6100 6200 6300 6400 6500 6600 6700 6800 6900 7000 7100 7200 7300 7400 7500 7600 7700 7800 7900 8000] 
#define FLASHLIGHT_LAG_AMOUNT 0.6 // How much the flashlight beam lags behind the player camera movement [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
#define FLASLIGHT_BRIGHTNESS 1.0 // The intensity of the night flashlight beam [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]

//Atmosphere

#define PRIMARY_STEPS 16 // Number of steps for the primary rays (More = slower but prettier) [6 7 8 9 10 11 12 13 14 15 16 20 24 30 40]
#define SECONDARY_STEPS 2 // Number of steps for the secondary rays (More = slower but prettier) [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]

#define PRIMARY_STEPS_LOD 4
#define SECONDARY_STEPS_LOD 0

#define ATMOSPHERE_INTENSITY 15.0 // How bright the atmosphere is [4.0 8.0 12.0 16.0 20.0 24.0 28.0 32.0 36.0 40.0]

#define FOG_INTENSITY 1.0 // How intense the morning and rain fog is [0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define FOG_OFFSET -50 // The height offset for atmosphere fog [-120 -110 -100 -90 -80-70 -60 -50 -40 -30 -20 -10 0 10 20 30 40 50 60 70 80 90 100 120 140 160 180 200 220]
#define FOG_QUALITY 8 // Number of fog ray steps [2 4 8 12]

#define PLANET_RADIUS 6371e3
#define ATMOSPHERE_RADIUS 6471e3

#define RAYLEIGH_COEFF_R 7.3e-6//8.05e-6
#define RAYLEIGH_COEFF_G 10.5e-6
#define RAYLEIGH_COEFF_B 33.1e-6//45.4e-6
#define RAYLEIGH_SCALE 8e3//6e3

#define MIE_COEFF 21e-6
#define MIE_SCALE 1.2e3
#define MIE_PREFERRED_DIR 0.758

//Sunlight
#define SUN_BRIGHTNESS 3.5 // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0 3.25 3.5 3.75 4.0 4.25 4.5 4.75 5.0 5.5 6.0 7.0]
// #define SHADOW_KERNEL_SIZE 7 // Higher = Smoother but slower [3 5 7 9 11 13]

//Ambient occlusion
#define AMBIENT_INTENSITY 1.25 // [0.5 0.75 1.0 1.25 1.5 1.75 2.0]
// #define RTAO_ENABLED // Ray traced Ambient Occlusion

//GLOBAL ILLUMINATION
#define ERGI_ENABLED // Equi-rectangular buffer global illumination
#define ERGI_RAYS 6 // Equirectangular GI rays [1 2 4 6 8 12 24]

//Block light
#define EMITTER_INTENSITY 1.0 // Brightness of light emitting blocks // [0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.2 2.4 2.6 2.8 3.0 3.5 4.0]
#define DAY_EMITTER_TEMP 3000 // The temperature in Kelvin (K) of light emitting blocks during daytime. Lower = Oranger, Higher = Bluer[3000 3500 4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000 5100 5200 5300 5400 5500 5600 5700 5800 5900 6000 6100 6200 6300 6400 6500 6600 6700 6800 6900 7000 7100 7200 7300 7400 7500 7600 7700 7800 7900 8000] 
#define NIGHT_TIME_UV // Emitters turn purple (UV) at night

//Material options
//water
#define WATER_WAVE_SPEED 1.0 // Speed multiplier of water waves [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0]
#define WATER_ABSORP_R 0.25 // How much water absorbs the red wavelength [0.0 0.03 0.06 0.09 0.12 0.15 0.18 0.21 0.25 0.3 0.35 0.4 0.5 0.55 0.6 0.65 0.7 0.8 0.9]
#define WATER_ABSORP_G 0.07 // How much water absorbs the green wavelength [0.0 0.03 0.06 0.09 0.12 0.15 0.18 0.21 0.25 0.3 0.35 0.4 0.5 0.55 0.6 0.65 0.7 0.8 0.9]
#define WATER_ABSORP_B 0.05 // How much water absorbs the blue wavelength [0.0 0.03 0.06 0.09 0.12 0.15 0.18 0.21 0.25 0.3 0.35 0.4 0.5 0.55 0.6 0.65 0.7 0.8 0.9]

//plants
#define WAVING_PLANTS_SPEED 1.0 // Speed multiplier of waving plants [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.5 3.0]

//Specular
#define SPECULAR_RAYS 4 // Number of specular rays sent (Higher = slower but less noise) [2 4 6 8 12 24]

//White world
//#define WHITE_WORLD // Makes everything have an albedo of 100%


//ACES
#define SAT_MOD                      0.0     // [-1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 -0.05 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define VIB_MOD                      0.0       // [-1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define CONT_MOD                     0.0         // [-0.4 -0.3 -0.2 -0.1 -0.09 -0.08 -0.07 -0.06 -0.05 -0.04 -0.03 -0.02 -0.01 0.0 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define CONT_MIDPOINT                0.5         // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define GAIN_MOD                     0.0         // [-1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define LIFT_MOD                     0.0         // [-10.0 -9.0 -8.0 -7.0 -6.0 -5.0 -4.0 -3.0 -2.0 -1.0 0.0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
#define WHITE_BALANCE                6300        // [4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000 5100 5200 5300 5400 5500 5600 5700 5800 5900 6000 6100 6200 6300 6400 6500 6600 6700 6800 6900 7000 7100 7200 7300 7400 7500 7600 7700 7800 7900 8000 8100 8200 8300 8400 8500 8600 8700 8800 8900 9000 9100 9200 9300 9400 9500 9600 9700 9800 9900 10000 10100 10200 10300 10400 10500 10600 10700 10800 10900 11000 11100 11200 11300 11400 11500 11600 11700 11800 11900 12000]     

#define Film_Slope                   0.75        //[0.0 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.10 1.20 1.30 1.40 1.50 1.60 1.70 1.80 1.90 2.00]
#define Film_Toe                     0.45        //[0.0 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define Film_Shoulder                0.95         //[0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.6 0.65 0.7 0.8 0.9 0.95 1.0]
#define Black_Clip                   0.0         //[0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.06 0.07 0.08 0.09 0.1]
#define White_Clip                   0.0       //[0.005 0.010 0.015 0.020 0.025 0.030 0.035 0.040 0.045 0.050 0.06 0.07 0.08 0.09 1.0]
#define Blue_Correction              0.0         //[1.0 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1 0.0 -0.1 -0.2 -0.3 -0.4 -0.5 -0.6 -0.7 -0.8 -0.9 -1.0]
#define Gamut_Expansion              4.0         //[0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]      

#define in_Match                     0.14        //[0.0 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.40]
#define Out_Match                    0.14        //[0.0 0.02 0.04 0.06 0.08 0.10 0.12 0.14 0.16 0.18 0.20 0.22 0.24 0.26 0.28 0.30 0.40]

//Camera effects
#define AUTO_EXPOSURE // Automatic exposure adjustment
#define EXPOSURE_SPEED 1.0// Automatic exposure adjustment speed [0.12 0.25 0.5 0.75 1.0 1.5 2.0 2.5]
#define MANUAL_EXPOSURE_AMOUNT 1.0 // Manual exposure adjustement amount [0.01 0.05 0.1 0.15 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.5 1.7 2.0 2.5 3.0 3.5 4.0 5.0 7.5 10.0 15.0]
#define LENSE_RAINDROPS // The rain drops that appear on the camera lense

//TAA
#define TAA_ENABLED // Temporal Anti-Aliasing (removes jaggy edges and noise) 
#define TAA_WEIGHT 0.95 // [0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95]