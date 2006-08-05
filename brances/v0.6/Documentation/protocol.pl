#!/usr/bin/perl

open FILE, "protocol_list.txt" or die "$!\n";
@lines = <FILE>;
close FILE;

foreach $line (@lines) {
	$line =~ m/^
		\s+
			(\d+)
		\s+
			(\S+)
		\s+
			(\S[^\[]*\S)
		\s+\[
			(.+)
		\]\s*
		$/x;
	$decimal = $1;
	$keyword = $2;
	$protocol = $3;
	$reference = $4;
	$keywords[$decimal] = $keyword;
	$protocols[$decimal] = $protocol;
	$references[$decimal] = $reference;
	#print "$decimal:$keyword:$protocol:$reference\n";
}

print '<?xml version="1.0" encoding="UTF-8"?>';
print "\n";
print '<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">';
print "\n";
print '<plist version="1.0">';
print "\n<array>\n";

for ( $i=0; $i<256; $i++ ) {
print <<EOF
	<dict>
		<key>Decimal</key>
		<string>$i</string>
		<key>Keyword</key>
		<string>$keywords[$i]</string>
		<key>Protocol</key>
		<string>$protocols[$i]</string>
		<key>References</key>
		<string>$references[$i]</string>
	</dict>
EOF
}

print <<EOF
</array>
</plist>
EOF
