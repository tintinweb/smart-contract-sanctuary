pragma solidity ^0.4.24;



// 數據合約
contract Second {

	// 長方形面積
	uint256 rectangleArea;

	function constructor() public{
  	}

  	// 取得長方形面積
  	function getRectangleArea(uint256 heigh, uint256 width) public returns(uint256){
  		rectangleArea = heigh * width;
  		return rectangleArea;
  	}

}