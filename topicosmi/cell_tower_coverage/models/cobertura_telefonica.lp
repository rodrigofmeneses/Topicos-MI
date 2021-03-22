\ Model cobertura_telefonica
\ LP format - for model browsing. Use MPS format to capture full model detail.
Maximize
  523 Y[0] + 690 Y[1] + 420 Y[2] + 1010 Y[3] + 1200 Y[4] + 850 Y[5]
   + 400 Y[6] + 1008 Y[7] + 950 Y[8]
Subject To
 Cobertura_região_0: - Y[0] + X[0] + X[1] + X[4] >= 0
 Cobertura_região_1: - Y[1] + X[0] >= 0
 Cobertura_região_2: - Y[2] + X[2] + X[3] + X[4] >= 0
 Cobertura_região_3: - Y[3] + X[2] + X[5] >= 0
 Cobertura_região_4: - Y[4] + X[2] + X[5] >= 0
 Cobertura_região_5: - Y[5] + X[0] + X[3] >= 0
 Cobertura_região_6: - Y[6] + X[2] + X[3] + X[4] >= 0
 Cobertura_região_7: - Y[7] + X[1] + X[4] >= 0
 Cobertura_região_8: - Y[8] + X[1] + X[4] + X[5] >= 0
 Orçamento: 4.2 X[0] + 6.1 X[1] + 5.2 X[2] + 5.5 X[3] + 4.8 X[4]
   + 9.2 X[5] <= 20
Bounds
Binaries
 Y[0] Y[1] Y[2] Y[3] Y[4] Y[5] Y[6] Y[7] Y[8] X[0] X[1] X[2] X[3] X[4] X[5]
End
