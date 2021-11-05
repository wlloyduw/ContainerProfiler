#!/bin/bash

sysbench --test=cpu --cpu-max-prime=20000 --max-requests=4000 run