/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity >=0.7.0 <0.9.0;

contract ShapeCreator {
    
    enum ShapeType { CIRCLE, SQUARE }
    enum StrokeWidth { THINNEST, THIN, NORMAL, THICKER }
    
    string svgWrapperStart = '<svg width="512" height="512" viewBox="0 0 512 512" fill="white" xmlns="http://www.w3.org/2000/svg">';
    string svgWrapperEnd = '</svg>';
    string shapeSvgPart1 = '<rect x="128" y="128" width="256" height="256" stroke="black" stroke-width="';
    string shapeSvgPart2 = '" rx="';
    string shapeSvgPart3 = '"/>';
    
    struct Shape {
        ShapeType shapeType;
        StrokeWidth strokeWidth;
    }
    
    Shape[] public createdShapes;
   
    function append(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f, string memory g) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e, f, g));
    }
    
    function createShape(ShapeType _shapeType, StrokeWidth _strokeWidth) public {
        createdShapes.push(Shape(_shapeType, _strokeWidth));
    }
    
    function getShapeSvgByIndex(uint256 index) public view returns(string memory){
        string[4] memory _widthStrings = ["1", "2", "4", "8"];
        string[2] memory _shapeBorderRadii = ["128", "0"];
        return append(svgWrapperStart, shapeSvgPart1, _widthStrings[uint(createdShapes[index].strokeWidth)], shapeSvgPart2, _shapeBorderRadii[uint(createdShapes[index].shapeType)], shapeSvgPart3, svgWrapperEnd);
    }
    
}