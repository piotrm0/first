/*
 *	types.h - basic types
 *	Project:	KIWI, useful items for platform-independence
 *	Author:		Rick C. Petty
 *
 * Copyright (C) 1993-2004 KIWI Computer.  All rights reserved.
 *
 * Please read the enclosed COPYRIGHT notice and LICENSE agreements, if
 * available.  All software and documentation in this file is protected
 * under applicable law as stated in the aforementioned files.  If not
 * included with this distribution, you can obtain these files, this
 * package, and source code for this and related projects from:
 *
 * http://www.kiwi-computer.com/
 *
 * $Id: types.h,v 1.3 2004/02/20 01:45:34 rick Exp $
 */

#ifndef __KIWI_TYPES_H__
#define __KIWI_TYPES_H__

#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/param.h>
#ifdef WIN32
#include <windef.h>
#endif /* WIN32 */


typedef unsigned char	byte;
typedef int		boolean_t;


#ifdef	__cplusplus
#define	BEGIN_DECLS	extern "C" {
#define	END_DECLS	}
#else	/* not C++ */
#define	BEGIN_DECLS
#define	END_DECLS
#endif	/* not C++ */
#define sizeofarray(array)	(sizeof(array) / sizeof((array)[0]))

typedef void (*void_fn_t)(void);
typedef int (*int_fn_t)(void);

/***  universal type  ***/
typedef	uint32_t	kiwi_t;
/*
 *  Comparison of two "kiwi" types; conversions to and from (macros):
 *	boolean_t kiwi_types_eq(kiwi_t t1, kiwi_t t2);
 *	kiwi_t    kiwi_typeint(uint32_t i);		// int -> kiwi_t
 *	kiwi_t    kiwi_typestr(const byte s[4]);	// str -> kiwi_t
 *	uint32_t  kiwi_type2int(kiwi_t k);		// kiwi_t -> int
 *	void      kiwi_type2str(kiwi_t k, byte s[4]);	// kiwi_t -> str
 */
#define kiwi_types_eq	((t1) == (t2))
#define kiwi_typeint(i)		((kiwi_t)((uint32_t)(i)))
#define kiwi_type2int(k)	((uint32_t)((kiwi_t)(k)))
#define kiwi_typestr(s) \
	    ((kiwi_t)(((((s)[0]<<24) | (s)[1]<<16) | (s)[2]<<8) | (s)[3]))
#define kiwi_type2str(s, k) \
	do { (s)[0]=((kiwi_t)(t) >>24; (s)[1]=((kiwi_t)(t)) >>16; \
	     (s)[2]=((kiwi_t)(t) >>8;  (s)[3]=((kiwi_t)(t)); } while (0)

/*
 *  Useful macros
 */
#ifndef ABS
#define ABS(x)		((x) < 0 ? -(x) : (x))
#endif /* !ABS */
#ifdef WIN32
#undef max
#undef min
#define MAX(x,y)	((x) > (y) ? (x) : (y))
#define MIN(x,y)	((x) < (y) ? (x) : (y))
#endif /* WIN32 */
#define PIN(n,mn,mx)	((mn) < (n) && (n) < (mx))
#ifndef CLAMP
#define CLAMP(n,mn,mx)	(MAX((mn), MIN((n), (mx))))
#endif /* !CLAMP */

/*
 *  CONCAT macro concatenates parts of symbol names into one symbol name
 *  STRING converts symbol name into string (stringify)
 *  XSTRING converts symbol name into string, after expanding macro
 */
#define CONCAT(x,y)	x ## y
#define STRING(x)	#x
#define XSTRING(x)	STRING(x)

#endif /* __KIWI_TYPES_H__ */
