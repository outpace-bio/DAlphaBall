c	Surface_only.f		Version 1 9/1/2008	Patrice Koehl

c	This file contains a suite of routines for computed the (weighted) surface
c	area of a union of balls. The calculation allows also computing
c	derivatives

c	Copyright (C) 2005 Patrice Koehl

c	This library is free software; you can redistribute it and/or
c	modify it under the terms of the GNU Lesser General Public
c	License as published by the Free Software Foundation; either
c	version 2.1 of the License, or (at your option) any later version.

c	This library is distributed in the hope that it will be useful,
c	but WITHOUT ANY WARRANTY; without even the implied warranty of
c	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
c	Lesser General Public License for more details.

c	You should have received a copy of the GNU Lesser General Public
c	License along with this library; if not, write to the Free Software
c	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#include "defines.h"

c	surface_only.f		Version 2 3/30/2007	Patrice Koehl

c	This subroutine builds the alpha complex based on the weighted
c	Delaunay triangulation

	subroutine surface_only(coef,WSurf,Surf,ballwsurf)

	integer	npointmax,ntetra_max,ntrig_max,nedge_max,nlink_max
	integer	ncortot

	parameter	(npointmax   = MAX_POINT)
	parameter	(ntetra_max  = MAX_TETRA)
	parameter	(nlink_max   = MAX_LINK)
	parameter	(ncortot     = 3*npointmax)

	integer i,j,k,l,m,n
	integer	ia,ib,ic,id
	integer	i1,i2,i3,i4
	integer	ntetra,ntrig,nedge
	integer	npoints,nvertex,nred
	integer idx,iflag
	integer irad,iattach
	integer	itrig,jtrig,iedge
	integer	trig1,trig2,trig_in,trig_out,triga,trigb
	integer	ncheck,icheck,option,isave
	integer jtetra,ktetra,npass,ipair,i_out,sum

	integer*1 ival,it1,it2

	integer	other3(3,4)
	integer face_info(2,6),face_pos(2,6)
	integer pair(2,6)
	integer	listcheck(nlink_max),tag(nlink_max)

	integer*1 tetra_info(ntetra_max)
	integer*1 tetra_nindex(ntetra_max)
	integer*1 tetra_mask(ntetra_max)
	integer*1 tetra_edge(ntetra_max)

c	Information on the tetrahedra of the regular
c	triangulation

	integer tetra(4,ntetra_max)
	integer tetra_neighbour(4,ntetra_max)

c	Information on the vertices

	integer*1 vertex_info(npointmax)

	real*8	ra,rb,rc,rd,ra2,rb2,rc2,rd2
	real*8	rab,rac,rad,rbc,rbd,rcd
	real*8	rab2,rac2,rad2,rbc2,rbd2,rcd2
	real*8	wa,wb,wc,wd,we,val
	real*8	alpha,scale,eps
	real*8	coefa,coefb,coefc,coefd,coefval
	real*8	surfa,surfb,surfc,surfd
	real*8	pi,twopi,precision
	real*8	a(3),b(3),c(3),d(3),e(3)
	real*8	radius(npointmax),weight(npointmax)
	real*8	coord(3*npointmax)

c	Results:

	real*8	WSurf,Surf
	real*8	coef(npointmax),ballwsurf(npointmax)

	common  /xyz_vertex/	coord,radius,weight
	common  /tetra_zone/    ntetra,tetra,tetra_neighbour
	common  /tetra_stat/    tetra_info,tetra_nindex
	common  /alp_zone/	tetra_edge
	common  /vertex_zone/   npoints,nvertex,vertex_info
	common  /gmp_info/	scale,eps
	common  /workspace/	tetra_mask
	common  /constants/	pi,twopi,precision

	data other3 /2,3,4,1,3,4,1,2,4,1,2,3/
	data face_info/1,2,1,3,1,4,2,3,2,4,3,4/
	data face_pos/2,1,3,1,4,1,3,2,4,2,4,3/
	data pair/3,4,2,4,2,3,1,4,1,3,1,2/
	data isave /0/

	save

	if(isave.eq.0) then
		pi = acos(-1.d0)
		twopi = 2.d0 * pi
		isave = 1
		precision = 1.0d-10
	endif

	Wsurf = 0
	Surf  = 0

	do 200 i = 1,nvertex
		ballwsurf(i) = 0
200	continue

	do 300 i = 1,ntetra
		tetra_mask(i) = 0
300	continue

c	loop over tetra, triangles and edges

	do 1600 idx = 1,ntetra

	    if(.not.btest(tetra_info(idx),1)) goto 1600

	    ia = tetra(1,idx)
	    ib = tetra(2,idx)
	    ic = tetra(3,idx)
	    id = tetra(4,idx)

	    do 400 i = 1,3
		a(i) = coord(3*(ia-1)+i)
		b(i) = coord(3*(ib-1)+i)
		c(i) = coord(3*(ic-1)+i)
		d(i) = coord(3*(id-1)+i)
400	    continue

	    ra = radius(ia)
	    rb = radius(ib)
	    rc = radius(ic)
	    rd = radius(id)

	    ra2 = ra*ra
	    rb2 = rb*rb
	    rc2 = rc*rc
	    rd2 = rd*rd

	    call distance2(coord,ia,ib,rab2,ncortot)
	    call distance2(coord,ia,ic,rac2,ncortot)
	    call distance2(coord,ia,id,rad2,ncortot)
	    call distance2(coord,ib,ic,rbc2,ncortot)
	    call distance2(coord,ib,id,rbd2,ncortot)
	    call distance2(coord,ic,id,rcd2,ncortot)

	    rab = sqrt(rab2)
	    rac = sqrt(rac2)
	    rad = sqrt(rad2)
	    rbc = sqrt(rbc2)
	    rbd = sqrt(rbd2)
	    rcd = sqrt(rcd2)

	    wa = 0.5d0*weight(ia)
	    wb = 0.5d0*weight(ib)
	    wc = 0.5d0*weight(ic)
	    wd = 0.5d0*weight(id)

	    coefa = coef(ia)
	    coefb = coef(ib)
	    coefc = coef(ic)
	    coefd = coef(id)

	    if(btest(tetra_info(idx),7)) then

	    	if(btest(tetra_info(idx),0)) then
			call foursphere_surf(a,b,c,d,ra,rb,rc,rd,
     1			ra2,rb2,rc2,rd2,rab,rac,rad,rbc,rbd,rcd,
     2			rab2,rac2,rad2,rbc2,rbd2,rcd2,wa,wb,wc,wd,
     3			surfa,surfb,surfc,surfd)
	   	else
			call foursphere_surf(a,b,d,c,ra,rb,rd,rc,
     1			ra2,rb2,rd2,rc2,rab,rad,rac,rbd,rbc,rcd,
     2			rab2,rad2,rac2,rbd2,rbc2,rcd2,wa,wb,wd,wc,
     3			surfa,surfb,surfd,surfc)
		   endif

		ballwsurf(ia) = ballwsurf(ia) - surfa
		ballwsurf(ib) = ballwsurf(ib) - surfb
		ballwsurf(ic) = ballwsurf(ic) - surfc
		ballwsurf(id) = ballwsurf(id) - surfd

	    endif

c	    Check triangles

	    do 700 itrig = 1,4

		jtetra = tetra_neighbour(itrig,idx)
		ival = ibits(tetra_nindex(idx),2*(itrig-1),2)
		jtrig = ival + 1

		if(jtetra.eq.0.or.jtetra.gt.idx) then

			if(btest(tetra_info(idx),2+itrig)) then
				call mvbits(tetra_info(idx),7,1,it1,0)
				if(jtetra.ne.0) then
			    		call mvbits(tetra_info(jtetra),
     1					7,1,it2,0)
				else
					it2 = 0
				endif
				coefval = 2 - it1 - it2
				if(coefval.eq.0) goto 700

				coefval = 0.5d0*coefval

				if(itrig.eq.1) then
					surfa = 0
					call threesphere_surf(b,c,d,rb,
     1					rc,rd,rb2,rc2,rd2,wb,wc,wd,rbc,
     2					rbd,rcd,rbc2,rbd2,rcd2,surfb,
     3					surfc,surfd)
				elseif(itrig.eq.2) then
					surfb = 0
					call threesphere_surf(a,c,d,ra,
     1					rc,rd,ra2,rc2,rd2,wa,wc,wd,rac,
     2					rad,rcd,rac2,rad2,rcd2,surfa,
     3					surfc,surfd)
				elseif(itrig.eq.3) then
					surfc = 0
					call threesphere_surf(a,b,d,ra,
     1					rb,rd,ra2,rb2,rd2,wa,wb,wd,rab,
     2					rad,rbd,rab2,rad2,rbd2,surfa,
     3					surfb,surfd)
				elseif(itrig.eq.4) then
					surfd = 0
					call threesphere_surf(a,b,c,ra,
     1					rb,rc,ra2,rb2,rc2,wa,wb,wc,rab,
     2					rac,rbc,rab2,rac2,rbc2,surfa,
     3					surfb,surfc)
				endif

				ballwsurf(ia) = ballwsurf(ia) + 
     1				coefval*surfa
				ballwsurf(ib) = ballwsurf(ib) + 
     1				coefval*surfb
				ballwsurf(ic) = ballwsurf(ic) + 
     1				coefval*surfc
				ballwsurf(id) = ballwsurf(id) + 
     1				coefval*surfd
			endif
		endif

700	    continue

c	    Now check edges
c					
	    do 1500 iedge = 1,6

		if(btest(tetra_mask(idx),iedge-1)) goto 1500

		if(.not.btest(tetra_edge(idx),iedge-1)) goto 1500

		surfa = 0
		surfb = 0
		surfc = 0
		surfd = 0

		if(iedge.eq.1) then
			call twosphere_surf(c,d,rc,rc2,rd,rd2,rcd,rcd2,
     1			surfc,surfd)
		elseif(iedge.eq.2) then
			call twosphere_surf(b,d,rb,rb2,rd,rd2,rbd,rbd2,
     1			surfb,surfd)
		elseif(iedge.eq.3) then
			call twosphere_surf(b,c,rb,rb2,rc,rc2,rbc,rbc2,
     1			surfb,surfc)
		elseif(iedge.eq.4) then
			call twosphere_surf(a,d,ra,ra2,rd,rd2,rad,rad2,
     1			surfa,surfd)
		elseif(iedge.eq.5) then
			call twosphere_surf(a,c,ra,ra2,rc,rc2,rac,rac2,
     1			surfa,surfc)
		elseif(iedge.eq.6) then
			call twosphere_surf(a,b,ra,ra2,rb,rb2,rab,rab2,
     1			surfa,surfb)
		endif

		ballwsurf(ia) = ballwsurf(ia) - surfa
		ballwsurf(ib) = ballwsurf(ib) - surfb
		ballwsurf(ic) = ballwsurf(ic) - surfc
		ballwsurf(id) = ballwsurf(id) - surfd

		icheck = 0

c		iedge is the edge number in the tetrahedron idx, with:
c		iedge = 1		(c,d)
c		iedge = 2		(b,d)
c		iedge = 3		(b,c)
c		iedge = 4		(a,d)
c		iedge = 5		(a,c)
c		iedge = 6		(a,b)
c		
c		Define indices of the edge

		i = tetra(pair(1,iedge),idx)
		j = tetra(pair(2,iedge),idx)

c		trig1 and trig2 are the two faces of idx that share
c		iedge
c		i1 and i2 are the positions of the third vertices of
c		trig1 and trig2

		trig1 = face_info(1,iedge)
		i1    = face_pos(1,iedge)
		trig2 = face_info(2,iedge)
		i2    = face_pos(2,iedge)

		i3 = tetra(i1,idx)
		i4 = tetra(i2,idx)

		call mvbits(tetra_info(idx),7,1,it1,0)

		if(btest(tetra_info(idx),2+trig2)) then
			icheck = icheck + 1
			listcheck(icheck) = i4
			jtetra = tetra_neighbour(trig2,idx)
			if(jtetra.ne.0) then
			    call mvbits(tetra_info(jtetra),7,1,it2,0)
			    tag(icheck) = it1 + it2
			else
			    tag(icheck) = it1
			endif
		endif

		if(btest(tetra_info(idx),2+trig1)) then
			icheck = icheck + 1
			listcheck(icheck) = i3
			jtetra = tetra_neighbour(trig1,idx)
			if(jtetra.ne.0) then
			    call mvbits(tetra_info(jtetra),7,1,it2,0)
			    tag(icheck) = it1 + it2
			else
			    tag(icheck) = it1
			endif
		endif

c		Now we look at the star of the edge:

		ktetra = idx
		npass = 1
		trig_out = trig1
		jtetra = tetra_neighbour(trig_out,ktetra)

800		continue

c		Leave this side of the star if we hit the convex hull

		if(jtetra.eq.0) goto 900
		call mvbits(tetra_info(jtetra),7,1,it1,0)

c		Leave the loop completely if we have described the
c		full cycle

		if(jtetra.eq.idx) goto 1000

c		Identify the position of iedge in tetrahedron jtetra

		if(i.eq.tetra(1,jtetra)) then
			if(j.eq.tetra(2,jtetra)) then
				ipair = 6
			elseif(j.eq.tetra(3,jtetra)) then
				ipair = 5
			else
				ipair = 4
			endif
		elseif(i.eq.tetra(2,jtetra)) then
			if(j.eq.tetra(3,jtetra)) then
				ipair = 3
			else
				ipair = 2
			endif
		else
			ipair = 1
		endif

		tetra_mask(jtetra) = ibset(tetra_mask(jtetra),ipair-1)

c		Find out the face we "went in"

		ival = ibits(tetra_nindex(ktetra),2*(trig_out-1),2)
		trig_in = ival + 1

c		We know the two faces of jtetra that share iedge:

		triga = face_info(1,ipair)
		i1    = face_pos(1,ipair)
		trigb = face_info(2,ipair)
		i2    = face_pos(2,ipair)

		trig_out = triga
		i_out = i1
		if(trig_in.eq.triga) then
			i_out = i2
			trig_out = trigb
		endif


		ktetra = jtetra
		jtetra = tetra_neighbour(trig_out,ktetra)
		if(jtetra.eq.idx) goto 1000

		if(btest(tetra_info(ktetra),2+trig_out)) then
			icheck = icheck + 1
			listcheck(icheck) = tetra(i_out,ktetra)
			if(jtetra.ne.0) then
			    call mvbits(tetra_info(jtetra),7,1,it2,0)
			    tag(icheck) = it1 + it2
			else
			    tag(icheck) = it1
			endif
		endif

		goto 800

900		continue

		if(npass.eq.2) goto 1000
		npass = npass + 1
		ktetra = idx
		trig_out = trig2
		jtetra = tetra_neighbour(trig_out,ktetra)
		goto 800

1000		continue

c		Now we have the list of triangles in the alpha complex
c		that are attached to the edge

c		If the edge is fully covered, skip!

		sum = 0
		do 1100 l = 1,icheck
			sum = sum + tag(l)
1100		continue

		if(sum.eq.2*icheck) goto 1500

1500	    continue

1600	continue

c	Now loop over vertices

	nred = 0
	do 1700 i = 1,nvertex

		if(.not.btest(vertex_info(i),0)) goto 1700

c		if vertex is not in alpha-complex, nothing to do...

		if(.not.btest(vertex_info(i),7)) goto 1700

c		Vertex is in alpha complex...

		ra = radius(i)
		ballwsurf(i) = ballwsurf(i) + 4*pi*ra*ra
c		
1700	continue

c	Compute total surface (weighted, and unweighted):

	do 1800 i = 1,nvertex
		WSurf = Wsurf + coef(i)*ballwsurf(i)
		Surf  = Surf  + ballwsurf(i)
		ballwsurf(i) = ballwsurf(i)*coef(i)
1800	continue

c	We are done...no derivatives in this routine ...

	return
	end
