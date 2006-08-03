/* headers for decoding packets */

#import <libc.h>

#import <netinet/in.h>
#import <net/ethernet.h>
#import <netinet/tcp_seq.h>
#include <netinet/tcp.h>

/* Ethernet header */
struct sniff_ethernet {
	u_char ether_dhost[ETHER_ADDR_LEN];
	u_char ether_shost[ETHER_ADDR_LEN];
	u_short ether_type;
};
/* IP header */
struct sniff_ip {
	#if BYTE_ORDER == LITTLE_ENDIAN
	u_int ip_hl:4;  // header length
	u_int ip_v:4;   // version
	#endif
	#if BYTE_ORDER == BIG_ENDIAN
	u_int ip_v:4;   // version
	u_int ip_hl:4;  // header length
	#endif
	u_char ip_tos;  // type of service
	u_short ip_len; // total length
	u_short ip_id;  // identification
	u_short ip_off; // fragment offset field
	#define IP_RF 0x8000	// reserved fragment flag
	#define IP_DF 0x4000	// don't fragment flag
	#define IP_MF 0x2000	// more fragments flag
	#define IP_OFFMASK 0x1fff   // mask for fragmenting bits
	u_char ip_ttl;  // time to live
	u_char ip_p;	// protocol
	u_short ip_sum; // checksum
	struct in_addr ip_src,ip_dst;   // source and destination address
};

struct sniff_tcp {
	u_short th_sport;   // source port
	u_short th_dport;   // destination port
	tcp_seq th_seq;		// sequence number
	tcp_seq th_ack;		// acknowledgement number
	#if BYTE_ORDER == LITTLE_ENDIAN
	u_int th_x2:4,   // (unused)
		th_off:4;		// data offset
	#endif
	#if BYTE_ORDER == BIG_ENDIAN
	u_int th_off:4,		// data offset
		th_x2:4;   // (unused)
	#endif
	u_char th_flags;
	#define TH_FIN 0x01
	#define TH_SYN 0x02
	#define TH_RST 0x04
	#define TH_PUSH 0x08
	#define TH_ACK 0x10
	#define TH_URG 0x20
	#define TH_ECE 0x40
	#define TH_CWR 0x80
	#define TH_FLAGS (TH_FIN|TH_SYN|TH_RST|TH_ACK|TH_URG|TH_ECE|TH_CWR)
	// no PUSH - why?
	u_short th_win; // window
	u_short th_sum; // checksum
	u_short th_urp; // urgent pointer
};