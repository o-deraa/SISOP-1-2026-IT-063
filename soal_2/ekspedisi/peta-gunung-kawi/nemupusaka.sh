#!/bin/bash

awk -F, '
{count++
x_total += $3
y_total += $4 }
END { 
x = x_total/count
y = y_total/count
print "Koordinat pusat:"
print x, y}' titik-penting.txt > posisipusaka.txt 2>/dev/null