# Hash-functions-based-on-quantum-walks-with-memory
The matlab code for hash functions based on quantum walks with one- and two-step memory

The main code for testing diffusion and confusion properties, the uniform distribution property, and collision resistance property is written in "main.m", which calls "collisionPerTrial.m" and "QHFM12.m".

The sensitivity test code is written in "sensitivityTest.m".

"collisonMeasure.m" is to measure the Kullback-Leibler divergence between the experimental and theoretical distribution of $\omega$ for each instances of QHFM and each existing schemes. "collisonMeasure.m" calls "hitsDistriDiverg.m".
