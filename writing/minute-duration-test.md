
# Do I Know How Long a Minute Is?

How accurate is my intuition for the duration of a minute? I am not sure, so I ran an experiment to find out.

For each data point, I would start a stopwatch, wait for what I thought was a minute, then stop the clock and record the results. I did not want my knowledge of the result to allow me to tune my perception, so I wrote a program that recorded my results without ever showing them to me (code included at end).

For the first batch of tests, I counted the minute in my head.


For the second batch of tests, I did not count the time and instead went purely on feel.


```
from datetime import datetime, timedelta
from math import floor

LOG_FILE = '/Users/briantracy/Desktop/minute_data.txt'

input('Press <enter> to start the test. 1 minute later, press <enter> again')
start = datetime.now()
input('Press <enter> at 1 minute')
stop = datetime.now()

unix_epoch_start = int(start.timestamp())
elapsed_millis = floor((stop - start) / timedelta(milliseconds=1))

with open(LOG_FILE, 'a') as f:
    f.write(f'{unix_epoch_start}:{elapsed_millis}\n')

```
