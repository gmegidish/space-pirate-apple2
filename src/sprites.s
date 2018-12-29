SPRITE0	hex 80 80  	;               
	hex 80 80  	;               
	hex e0 87  	;     xxxxx     
	hex a0 80  	;         x     
	hex a0 80  	;         x     
	hex c0 87  	;     xxxx      
	hex 98 87  	;     xxx  xx   
	hex b6 90  	;   x     xx xx 
	hex ee b7  	;  xx xxxxx xxx 
	hex ee b7  	;  xx xxxxx xxx 
	hex 84 80  	;            x  
	hex a1 c4  	; x   x   x    x
	hex e3 e7  	; xx  xxxxx   xx
	hex d3 e3  	; xx   xxx x  xx
	hex b9 cc  	; x  xx   xxx  x
	hex f8 82  	;      x xxxx   
	hex 90 8c  	;    xx    x    
	hex e0 80  	;        xx     
	hex 8c 86  	;     xx    xx  
	hex b4 9a  	;   xx x  xx x  

SPRITE1	hex 80 80  	;               
	hex 80 80  	;               
	hex e0 87  	;     xxxxx     
	hex a0 80  	;         x     
	hex a0 80  	;         x     
	hex c0 87  	;     xxxx      
	hex 98 87  	;     xxx  xx   
	hex b6 90  	;   x     xx xx 
	hex ee b7  	;  xx xxxxx xxx 
	hex ee b7  	;  xx xxxxx xxx 
	hex a1 c4  	; x   x   x    x
	hex d7 e3  	; xx   xxx x xxx
	hex bb ed  	; xx xx x xxx xx
	hex f9 ce  	; x  xxx xxxx  x
	hex 88 86  	;     xx    x   
	hex b0 9a  	;   xx x  xx    
	hex 86 80  	;            xx 
	hex 82 e0  	; xx          x 
	hex 88 98  	;   xx      x   
	hex 90 88  	;    x     x    

SPRITE2	hex 80 80  	;               
	hex 80 80  	;               
	hex f0 83  	;      xxxxx    
	hex 80 82  	;      x        
	hex 80 82  	;      x        
	hex f0 81  	;       xxxx    
	hex f0 8c  	;    xx  xxx    
	hex 84 b6  	;  xx xx     x  
	hex f6 bb  	;  xxx xxxxx xx 
	hex f6 bb  	;  xxx xxxxx xx 
	hex 80 90  	;   x           
	hex 91 c2  	; x    x   x   x
	hex f3 e3  	; xx   xxxxx  xx
	hex e3 e5  	; xx  x xxx   xx
	hex 99 ce  	; x  xxx   xx  x
	hex a0 8f  	;    xxxx x     
	hex 98 84  	;     x    xx   
	hex 80 83  	;      xx       
	hex b0 98  	;   xx    xx    
	hex ac 96  	;   x xx  x xx  

SPRITE3	hex 80 80  	;               
	hex 80 80  	;               
	hex f0 83  	;      xxxxx    
	hex 80 82  	;      x        
	hex 80 82  	;      x        
	hex f0 81  	;       xxxx    
	hex f0 8c  	;    xx  xxx    
	hex 84 b6  	;  xx xx     x  
	hex f6 bb  	;  xxx xxxxx xx 
	hex f6 bb  	;  xxx xxxxx xx 
	hex 91 c2  	; x    x   x   x
	hex e3 f5  	; xxx x xxx   xx
	hex db ee  	; xx xxx x xx xx
	hex b9 cf  	; x  xxxx xxx  x
	hex b0 88  	;    x    xx    
	hex ac 86  	;     xx  x xx  
	hex 80 b0  	;  xx           
	hex 83 a0  	;  x          xx
	hex 8c 88  	;    x      xx  
	hex 88 84  	;     x     x   

SPRITE4	hex 80 80  	;               
	hex c0 c3  	; x    xxx      
	hex e0 c7  	; x   xxxxx     
	hex c0 e3  	; xx   xxx      
	hex a0 c4  	; x   x   x     
	hex e8 87  	;     xxxxx x   
	hex dc 9b  	;   xx xxx xxx  
	hex ba 9c  	;   xxx   xxx x 
	hex f8 bf  	;  xxxxxxxxxx   
	hex 81 b0  	;  xx          x
	hex a3 84  	;     x   x   xx
	hex e7 87  	;     xxxxx  xxx
	hex d1 8b  	;    x xxx x   x
	hex b2 8c  	;    xx   xx  x 
	hex c0 8e  	;    xxx x      
	hex b0 82  	;      x  xx    
	hex b0 80  	;         xx    
	hex a8 8c  	;    xx   x x   
	hex b0 8c  	;    xx   xx    
	hex 80 b4  	;  xx x         

SPRITE5	hex f1 83  	;      xxxxx   x
	hex e0 81  	;       xxx     
	hex 93 82  	;      x   x  xx
	hex f1 83  	;      xxxxx   x
	hex e8 8d  	;    xx xxx x   
	hex 9c 9e  	;   xxxx   xxx  
	hex fd af  	;  x xxxxxxxxx x
	hex fe 8f  	;    xxxxxxxxxx 
	hex 86 c0  	; x          xx 
	hex 90 e2  	; xx   x   x    
	hex f0 f3  	; xxx  xxxxx    
	hex e8 c5  	; x   x xxx x   
	hex 98 a6  	;  x  xx   xx   
	hex b8 81  	;       x xxx   
	hex a0 86  	;     xx  x     
	hex 80 86  	;     xx        
	hex 98 8a  	;    x x   xx   
	hex 98 86  	;     xx   xx   
	hex 96 80  	;          x xx 
	hex 98 80  	;          xx   


SPRLO	db <SPRITE0
	db <SPRITE1
	db <SPRITE2
	db <SPRITE3
	db <SPRITE4
	db <SPRITE5

SPRHI	db >SPRITE0
	db >SPRITE1
	db >SPRITE2
	db >SPRITE3
	db >SPRITE4
	db >SPRITE5

