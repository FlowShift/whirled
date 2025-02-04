﻿package org.papervision3d.core.math
{
	import org.papervision3d.Papervision3D;
	
/**
* The Number3D class represents a value in a three-dimensional coordinate system.
*
* Properties x, y and z represent the horizontal, vertical and z the depth axes respectively.
*
*/
public class Number3D
{
	/**
	* The horizontal coordinate value.
	*/
	public var x: Number;

	/**
	* The vertical coordinate value.
	*/
	public var y: Number;

	/**
	* The depth coordinate value.
	*/
	public var z: Number;

	/**
	 * pre-made Number3D : used by various methods as a way to temporarily store Number3Ds. 
	 */
	static private var temp : Number3D = Number3D.ZERO; 
	
	static public var toDEGREES :Number = 180/Math.PI;
	static public var toRADIANS :Number = Math.PI/180;
	
	/**
	* Creates a new Number3D object whose three-dimensional values are specified by the x, y and z parameters. If you call this constructor function without parameters, a Number3D with x, y and z properties set to zero is created.
	*
	* @param	x	The horizontal coordinate value. The default value is zero.
	* @param	y	The vertical coordinate value. The default value is zero.
	* @param	z	The depth coordinate value. The default value is zero.
	*/
	public function Number3D( x: Number=0, y: Number=0, z: Number=0 )
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}


	/**
	* Returns a new Number3D object that is a clone of the original instance with the same three-dimensional values.
	*
	* @return	A new Number3D instance with the same three-dimensional values as the original Number3D instance.
	*/
	public function clone():Number3D
	{
		return new Number3D( this.x, this.y, this.z );
	}
	
	/**
	 * Copies the values of this Number3d to the passed Number3d.
	 * 
	 */
	public function copyTo(n:Number3D):void
	{
		n.x = x;
		n.y = y;
		n.z = z;
	}	
	/**
	 * Copies the values of this Number3d to the passed Number3d.
	 * 
	 */
	public function copyFrom(n:Number3D):void
	{
		x = n.x; 
		y = n.y; 
		z = n.z; 
	}
	
	/** 
	 * Quick way to set the properties of the Number3D
	 * 
	 */
	public function reset(newx:Number = 0, newy:Number = 0, newz:Number = 0):void
	{
		x = newx; 
		y = newy; 
		z = newz; 
	}

	// ______________________________________________________________________ MATH

	/**
	* Modulo
	*/

	public function get modulo() : Number
	{
		return Math.sqrt( this.x*this.x + this.y*this.y + this.z*this.z );
	}

	/**
	* Add
	*/
	public static function add( v:Number3D, w:Number3D ):Number3D
	{
		return new Number3D
		(
			v.x + w.x,
			v.y + w.y,
			v.z + w.z
		);
	}

	/**
	 * Subtract.
	 */
	public static function sub( v:Number3D, w:Number3D ):Number3D
	{
		return new Number3D
		(
			v.x - w.x,
			v.y - w.y,
			v.z - w.z
		);
	}

	/**
	 * Dot product.
	 */
	public static function dot( v:Number3D, w:Number3D ):Number
	{
		return ( v.x * w.x + v.y * w.y + w.z * v.z );
	}

	/**
	 * Cross product. Now optionally takes a target Number3D to put the change into. So we're not constantly making new number3Ds. 
	 * Maybe make a crossEq function? 
	 */
	public static function cross( v:Number3D, w:Number3D, targetN:Number3D = null ):Number3D
	{
		if(!targetN) targetN = ZERO; 
		 
		targetN.reset((w.y * v.z) - (w.z * v.y), (w.z * v.x) - (w.x * v.z), (w.x * v.y) - (w.y * v.x));
		return targetN; 
	}



	/**
	 * Normalize.
	 */
	public function normalize():void
	{
		var mod:Number = this.modulo;

		if( mod != 0 && mod != 1)
		{
			this.x /= mod;
			this.y /= mod;
			this.z /= mod;
		}
	}
	/**
	 * Multiplies the vector by a number. The same as the *= operator
	 */
	public function multiplyEq(n:Number):void
	{
		x*=n; 
		y*=n;
		z*=n; 	
	}
	
	/**
	 * Adds the vector passed to this vector. The same as the += operator. 
	 */
	public function plusEq(v:Number3D):void
	{
		x+=v.x; 
		y+=v.y; 
		z+=v.z; 	
	}
	
	/**
	 * Subtracts the vector passed to this vector. The same as the -= operator. 
	 */
	
	public function minusEq(v:Number3D):void
	{
		x -= v.x; 
		y -= v.y; 
		z -= v.z; 	
		
	}

	// ______________________________________________________________________
	
	/**
	 * Super fast modulo(length, magnitude) comparisons.
	 * 
	 *  
	 */
	public function isModuloLessThan(v:Number):Boolean
	{
			
		return (moduloSquared<(v*v)); 
		
	}
	
	public function isModuloGreaterThan(v:Number):Boolean
	{
			
		return (moduloSquared>(v*v)); 
		
	}
	public function isModuloEqualTo(v:Number):Boolean
	{
			
		return (moduloSquared==(v*v)); 
		
	}
		
	public function get moduloSquared():Number
	{
		return ( this.x*this.x + this.y*this.y + this.z*this.z );
	}
	
	
	// ______________________________________________________________________



	/**
	* Returns a Number3D object with x, y and z properties set to zero.
	*
	* @return A Number3D object.
	*/
	static public function get ZERO():Number3D
	{
		return new Number3D( 0, 0, 0 );
	}


	/**
	* Returns a string value representing the three-dimensional values in the specified Number3D object.
	*
	* @return	A string.
	*/
	public function toString(): String
	{
		return 'x:' + Math.round(x*100)/100 + ' y:' + Math.round(y*100)/100 + ' z:' + Math.round(z*100)/100;		
	
	}
	
	//------- TRIG FUNCTIONS
	
	/**
	 * 
	 * 
	 * 
	 */
	
	public function rotateX(angle:Number) :void
	{
		if(Papervision3D.useDEGREES) angle*= toRADIANS; 
		
		var cosRY:Number = Math.cos(angle);
		var sinRY:Number = Math.sin(angle);

		temp.copyFrom(this); 

		this.y = (temp.y*cosRY)-(temp.z*sinRY);
		this.z = (temp.y*sinRY)+(temp.z*cosRY);
		
	}	

	public function rotateY(angle:Number) :void
	{
		
		if(Papervision3D.useDEGREES) angle*= toRADIANS; 
		
		var cosRY:Number = Math.cos(angle);
		var sinRY:Number = Math.sin(angle);

		temp.copyFrom(this); 
		
		this.x= (temp.x*cosRY)+(temp.z*sinRY);
		this.z= (temp.x*-sinRY)+(temp.z*cosRY);
		
		
	}	
	public function rotateZ(angle:Number) :void
	{
		
		if(Papervision3D.useDEGREES) angle*= toRADIANS; 

		var cosRY:Number = Math.cos(angle);
		var sinRY:Number = Math.sin(angle);

		temp.copyFrom(this); 		
		//this.x= temp.x;
		this.x= (temp.x*cosRY)-(temp.y*sinRY);
		this.y= (temp.x*sinRY)+(temp.y*cosRY);
		
		
	}
}
}