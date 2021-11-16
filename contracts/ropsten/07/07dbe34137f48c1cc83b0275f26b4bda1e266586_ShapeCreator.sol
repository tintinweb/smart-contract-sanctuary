/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

pragma solidity >=0.7.0 <0.9.0;

contract ShapeCreator {
    
    enum ShapeType { CIRCLE, SQUARE }
    enum StrokeWidth { THINNEST, THIN, NORMAL, THICKER }
    
    string svgWrapperStart = '<svg viewBox="0 0 16384 16384" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="16384" height="16384" fill="white"/>';
    string svgWrapperEnd = '</svg>';
    string shapeSvgPart1 = '<rect stroke="black" x="';
    string shapeSvgPart2 = '" y="';
    string shapeSvgPart3 = '" width="';
    string shapeSvgPart4 = '" height="';
    string shapeSvgPart5 = '" stroke-width="';
    string shapeSvgPart6 = '" rx="';
    string shapeSvgPart7 = '"/>';
    uint256 baseX = 24;
    uint256 stepX = 24;
    uint256 baseWidth = 16336;
    uint256 stepWidth = 48;
    uint256 subshapeCount = 320;
    
    
    struct Shape {
        ShapeType shapeType;
        StrokeWidth strokeWidth;
    }
    
    Shape[] public createdShapes;
   
    function append6(string memory a, string memory b, string memory c, string memory d, string memory e, string memory f) internal pure returns (string memory){
        return string(abi.encodePacked(a, b, c, d, e, f));
    }
    
    function append4(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }
    
    
    function append3(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
    
     function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    function uintToStr(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    
    function createShape(ShapeType _shapeType, StrokeWidth _strokeWidth) public {
        createdShapes.push(Shape(_shapeType, _strokeWidth));
    }
    
    function createdShapesLength() public view returns(uint){
        return createdShapes.length;
    }
    
    function getShapeSvgByIndex(uint256 index) public view returns(string memory){
        string[4] memory _widthStrings = ["1", "2", "4", "8"];
        string[2] memory _shapeBorderRadii = ["100000", "0"];
        string memory svgString = '';
        uint strokeWidthIndex = uint(createdShapes[index].strokeWidth);
        string memory valueStrokeWidth = _widthStrings[strokeWidthIndex];
        uint shapeBorderRadiusIndex = uint(createdShapes[index].shapeType);
        string memory  valueBorderRadius = _shapeBorderRadii[shapeBorderRadiusIndex];
        uint256 i;
        for(i = 0; i < subshapeCount; i++){
            svgString = append6(svgString, shapeSvgPart1, uintToStr(baseX + stepX * i), shapeSvgPart2, uintToStr(baseX + stepX * i), shapeSvgPart3);
            svgString = append6(svgString, uintToStr(baseWidth - stepWidth * i), shapeSvgPart4, uintToStr(baseWidth - stepWidth * i), shapeSvgPart5, valueStrokeWidth); 
            svgString = append4(svgString, shapeSvgPart6, valueBorderRadius, shapeSvgPart7);
        }
        return append3(svgWrapperStart, svgString, svgWrapperEnd);
    }
    
}