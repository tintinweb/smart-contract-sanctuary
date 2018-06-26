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






// 控制合約
contract Main {


	// 總面積
	uint256 allArea;

	// 數據合約
	Second secondContract;


	function constructor(address _secondContractAddr) public{
		secondContract = Second(_secondContractAddr);
  	}
	

	// 取得正方形面積
	function getSquareArea(uint256 width) public returns(uint256){
		uint256 squareArea = width * width;
		return squareArea;
	}
	

	// 取得總面積
	function getAllArea()  public returns(uint256) {

		// 長方形面積
		uint256 rectangleArea = secondContract.getRectangleArea(5, 21);
		// 正方形面積
		uint256 squareArea = getSquareArea(10);
		// 加總面積
		allArea = rectangleArea + squareArea;
		return allArea;

	}
	
}