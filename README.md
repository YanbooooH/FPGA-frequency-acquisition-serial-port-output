# FPGA-frequency-acquisition-serial-port-output（在FPGA上实现频率采集，并通过串口来输出）


在FPGA上实现频率采集方案，频率稳定到HZ的后一位，并通过串口发送到上位机

**目标频率采集范围**：15kHz~80kHz
**频率采集精度**：精确到0.1Hz（待定）
**采集相应速度**：100ms（待定）

经调研，决定使用等精度采样的方法来实现。

![image](https://user-images.githubusercontent.com/120769776/209263745-418ab06b-2a7d-4368-8951-8311674e3ce0.png)


                                               
