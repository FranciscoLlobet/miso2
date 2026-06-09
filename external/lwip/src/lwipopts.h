/*
 * Copyright 2025 Francisco Llobet-Blandino
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * lwIP configuration for FRDM-MCXE247 (Cortex-M4, 256 kB SRAM), bare-metal.
 *
 * Consumer code that needs OS support (FreeRTOS) must supply its own
 * lwipopts.h earlier on the include path and set NO_SYS=0 together with a
 * sys_arch implementation.
 */

#ifndef LWIPOPTS_H
#define LWIPOPTS_H

#define ETH_LINK_POLLING_INTERVAL_MS 1500U
#define ETH_MAX_RX_PKTS_AT_ONCE 0U
#define ETH_USE_GPIO_ADAPTER 1
#define ENET_RXBUFF_SIZE 1518U
#define ENET_TXBUFF_SIZE 1514U
#define ENET_RXBD_NUM 5U
#define ENET_RXBUFF_NUM (ENET_RXBD_NUM * 2)
#define ENET_TXBD_NUM 3U

#define MEMCPY(dst,src,len) memcpy(dst,src,len)
#define SMEMCPY(dst,src,len) memcpy(dst,src,len)
#define MEMMOVE(dst,src,len) memmove(dst,src,len)

extern void sys_check_core_locking(void);
extern void sys_lock_tcpip_core(void);
extern void sys_unlock_tcpip_core(void);
extern void sys_check_core_locking(void);
extern void sys_mark_tcpip_thread(void);
/* =========================================================================
 * Operating mode
 * =========================================================================
 * NO_SYS=1: bare-metal / polling mode. No OS threads, no mutexes.
 * Callers must drive lwip_timers_check_timeouts() from the main loop.
 * sys_now() must be provided by the application (returns milliseconds).
 */
#define NO_SYS 0

/* SYS_LIGHTWEIGHT_PROT=0: disable the sys_prot_t / sys_arch_protect()
 * critical-section mechanism.  With NO_SYS=1 and a single-threaded polling
 * model there is nothing to protect against; enabling this would require
 * implementing sys_arch_protect/sys_arch_unprotect stubs. */
#define SYS_LIGHTWEIGHT_PROT 1

#define LWIP_ASSERT_CORE_LOCKED( ) sys_check_core_locking()
#define LWIP_TIMERS 1

/* =========================================================================
 * Memory configuration  (256 kB total SRAM on MCXE247)
 * =========================================================================
 * Heap is used for pbuf payloads and dynamic structures when pool is full.
 */
#define MEM_ALIGNMENT           4
#define MEM_SIZE                (22*1024)   /* 16 kB general heap */

/* =========================================================================
 * Sequential API (netconn / sockets) — disabled in NO_SYS=1 mode
 * =========================================================================
 * memp.c unconditionally includes api_msg.h; disabling these suppresses
 * the #error it emits when NO_SYS=1 and LWIP_NETCONN is still enabled. */
#define LWIP_NETCONN            1
#define LWIP_SOCKET             1

/* =========================================================================
 * Memory pool sizes
 * ========================================================================= */
/* IP_REASS_MAX_PBUFS must be < (ENET_RXBUFF_NUM - ENET_RXBD_NUM).
 * Defaults: ENET_RXBD_NUM=5, ENET_RXBUFF_NUM=10 → gap=5.
 * MEMP_NUM_REASSDATA must be <= IP_REASS_MAX_PBUFS. */
#define IP_REASS_MAX_PBUFS      4
#define MEMP_NUM_REASSDATA      4

#define MEMP_NUM_PBUF 15U
#define MEMP_NUM_RAW_PCB 4U
#define MEMP_NUM_UDP_PCB 6U
#define MEMP_NUM_TCP_PCB 10U
#define MEMP_NUM_TCP_PCB_LISTEN 6U
#define MEMP_NUM_TCP_SEG 22U
#define MEMP_NUM_ALTCP_PCB 10U
#define MEMP_NUM_REASSDATA 2U
#define MEMP_NUM_FRAG_PBUF 15U
#define MEMP_NUM_ARP_QUEUE 30U
#define MEMP_NUM_IGMP_GROUP 8U
#define MEMP_NUM_SYS_TIMEOUT 10
#define MEMP_NUM_NETBUF 2U
#define MEMP_NUM_NETCONN 4U
#define MEMP_NUM_SELECT_CB 4U
#define MEMP_NUM_TCPIP_MSG_API 8U
#define MEMP_NUM_TCPIP_MSG_INPKT 8U
#define MEMP_NUM_NETDB 1U
#define MEMP_NUM_LOCALHOSTLIST 1U
#define PBUF_POOL_SIZE 5U
#define MEMP_NUM_API_MSG 8U
#define MEMP_NUM_DNS_API_MSG 8U
#define MEMP_NUM_SOCKET_SETGETSOCKOPT_DATA 8U
#define MEMP_NUM_NETIFAPI_MSG 8U

/* =========================================================================
 * Pbuf pool
 * ========================================================================= */
#define PBUF_POOL_SIZE          16
/* Full Ethernet frame (1500 payload + 14 header + 4 CRC rounding) */
#define PBUF_POOL_BUFSIZE       LWIP_MEM_ALIGN_SIZE(TCP_MSS+PBUF_IP_HLEN+PBUF_TRANSPORT_HLEN+PBUF_LINK_ENCAPSULATION_HLEN+PBUF_LINK_HLEN)
/* =========================================================================
 * TCP
 * ========================================================================= */
#define LWIP_TCP                1
#define TCP_MSS                 1460
#define TCP_WND                 (4 * TCP_MSS)
#define TCP_SND_BUF             (4 * TCP_MSS)
#define TCP_SND_QUEUELEN        (2 * TCP_SND_BUF / TCP_MSS)
#define LWIP_TCP_KEEPALIVE      1

/* =========================================================================
 * UDP
 * ========================================================================= */
#define LWIP_UDP                1

/* =========================================================================
 * IPv4 protocols
 * ========================================================================= */
#define LWIP_ARP                1
#define ARP_TABLE_SIZE          10
#define ARP_QUEUEING            1

#define LWIP_ICMP               1

#define LWIP_IGMP               0   /* multicast — enable when needed */

#define LWIP_DHCP               1
#define LWIP_DHCP_MAX_NTP_SERVERS 1U
#define LWIP_DHCP_MAX_DNS_SERVERS 2U
#define LWIP_DHCP_DISCOVER_ADD_HOSTNAME 1
#define LWIP_DHCP_AUTOIP_COOP_TRIES 9U

#define LWIP_DHCP_DOES_ACD_CHECK 0  /* skip ARP conflict-check, saves a round-trip */

#define LWIP_AUTOIP             0

#define LWIP_DNS                1
#define DNS_TABLE_SIZE          4
#define DNS_MAX_SERVERS         2

/* =========================================================================
 * IPv6 — disabled; enable when needed
 * ========================================================================= */
#define LWIP_IPV6               0

/* =========================================================================
 * Ethernet / netif
 * ========================================================================= */
#define LWIP_ETHERNET           1
#define LWIP_NETIF_HOSTNAME     1
#define LWIP_NETIF_STATUS_CALLBACK  1
#define LWIP_NETIF_EXT_STATUS_CALLBACK 1
#define LWIP_NETIF_LINK_CALLBACK    1
#define LWIP_SINGLE_NETIF 1


#define TCPIP_THREAD_NAME "tcpip_thread"
#define TCPIP_THREAD_STACKSIZE 4096U
#define TCPIP_THREAD_PRIO 8
#define TCPIP_MBOX_SIZE 32U
#define LWIP_TCPIP_THREAD_ALIVE( ) 
#define SLIPIF_THREAD_NAME "slipif_loop"
#define SLIPIF_THREAD_STACKSIZE 0U
#define SLIPIF_THREAD_PRIO 1
#define DEFAULT_THREAD_NAME "lwIP"
#define DEFAULT_THREAD_STACKSIZE 3000U
#define DEFAULT_THREAD_PRIO 3
#define DEFAULT_RAW_RECVMBOX_SIZE 12U
#define DEFAULT_UDP_RECVMBOX_SIZE 12U
#define DEFAULT_TCP_RECVMBOX_SIZE 12U
#define DEFAULT_ACCEPTMBOX_SIZE 12U

#define LWIP_NETCONN_SEM_PER_THREAD     0

#define LWIP_TCPIP_CORE_LOCKING 1
#define LOCK_TCPIP_CORE_CUSTOM( ) sys_lock_tcpip_core()
#define LOCK_TCPIP_CORE( ) sys_lock_tcpip_core()
#define UNLOCK_TCPIP_CORE_CUSTOM( ) sys_unlock_tcpip_core()
#define UNLOCK_TCPIP_CORE( ) sys_unlock_tcpip_core()
/* =========================================================================
 * Checksums
 * ========================================================================= */
/* Set CHECKSUM_GEN_* and CHECKSUM_CHECK_* to 0 when the hardware ENET MAC
 * offloads checksums; leave at 1 (software) for now. */
#define CHECKSUM_GEN_IP         0
#define CHECKSUM_GEN_UDP        1
#define CHECKSUM_GEN_TCP        1
#define CHECKSUM_CHECK_IP       0
#define CHECKSUM_CHECK_UDP      1
#define CHECKSUM_CHECK_TCP      1

#define LWIP_NETIF_API          1


/* =========================================================================
 * Statistics & debug — off by default, enable per-module during bring-up
 * ========================================================================= */
#define LWIP_STATS              0
#define LWIP_DEBUG              1

/* Uncomment individual modules to enable their debug output:
 * #define ETHARP_DEBUG         LWIP_DBG_ON
 * #define NETIF_DEBUG          LWIP_DBG_ON
 * #define IP_DEBUG             LWIP_DBG_ON
 * #define TCP_DEBUG            LWIP_DBG_ON
 * #define DHCP_DEBUG           LWIP_DBG_ON
 */
#define DHCP_DEBUG LWIP_DBG_ON
#define UDP_DEBUG  LWIP_DBG_ON

#endif /* LWIPOPTS_H */
