# Hawler Traffic Police
A simple script to check your Hawler Traffic Police fines in the terminal.

## Quick Start
This is just a shell script, pretty much works on any GNU/Linux machine with minimum requirements. You can get the script using either of the following commands.

```
curl -O https://raw.githubusercontent.com/mastawbeqezwan/hawler-traffic-police/refs/heads/main/htp.sh
```

```
git clone https://github.com/mastawbeqezwan/hawler-traffic-police.git
cd hawler-traffic-police
```
Make it executable
```
chmod +x htp.sh
```

## Usage
To check your fines use the following syntax, please ignore the [Plate Character] if you have an old plate with no character.
```
/htp.sh <Vehicle Type> [<Plate Character>] <Plate Number> <Registration Number>
```
Available vehicle types:
```
p | private
r | rental
l | load
a | agricultural
c | commercial
m | motorcycle
```
Examples:
```
./htp.sh private F 123 0123456
./htp.sh c B 123 0123456
./htp.sh motorcycle 123 0123456     (without Plate Character)
```

