import pyodbc

conn = pyodbc.connect('Driver={SQL Server};'
                        'Server=DESKTOP-P1PUDIP;'
                        'Database=EVDAcres;'
                        'Trusted_Connection=yes;')

cursor = conn.cursor()
cursor.execute('SELECT TOP (10) [priKey]'
      ',[hostDeviceId]'
      ',[eventCode]'
      ',[amount]'
      ',[idPatron]'
      ',[CI]'
      ',[CO]'
      ',[gamesPlayed]'
      ',[eventTime]'
      ',[eventTimeAsDate]'
      ',[hostTime]'
      ',[cachePriKey]'
      ',[t]'
      ',[datenum]'
      ',[tod]'
      ',[tRef]'
  'FROM [EVDAcres].[dbo].[EVD]')

for row in cursor:
    print(row)
