pragma solidity ^0.4.24;


// 引入其他library
// import &quot;./Custom.library&quot;;


contract Part1 {

	// 長方形面積
	uint rectangleArea;

  	// 取得- 長方形面積
  	function getRectangleArea(uint heigh, uint width) public returns(uint){
  		rectangleArea = heigh * width;
  		return rectangleArea;
  	}

}







contract PartMain2 {



	Part1 part1;

	// 長方形面積
	uint rectangleArea;
	// 正方形面積
	uint squareArea;
	// 全面總面積
	uint allArea;




	// 取得- 正方形面積
	function getSquareArea(uint width) public returns(uint){
		squareArea = width * width;
		return squareArea;
	}
	

	// 取得- 總面積
	function getAllArea()  public returns(uint) {

		// 長方形面積
		rectangleArea = part1.getRectangleArea(5, 21);
		// 正方形面積
		squareArea = getSquareArea(10);
		// 加總面積
		allArea = rectangleArea + squareArea;
		return allArea;


	}
	
	



}