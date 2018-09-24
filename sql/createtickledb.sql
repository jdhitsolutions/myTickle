CREATE DATABASE $DatabaseName
ON PRIMARY
    (FILENAME = '<insert path to database file>',
    NAME = TickleEvents,
    SIZE = 10mb,
    MAXSIZE = 100,
    FILEGROWTH = 20
    )