// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./Base64.sol";

/// @title PuzzleGenerator
/// @notice Provides functionaliy to create mondrian puzzles, svg-representations and metadata
library PuzzleGenerator {

    struct Rect {
        uint x; 
        uint y;
        uint width;
        uint height;
        Color color;
    }
    
    enum Color {
        red,
        blue,
        white,
        yellow,
        black
     }

    struct Traits {
        uint score;
        string dominantColor;
        uint rectangles;
    }

    uint8 constant denominator = 20;
    uint8 constant tolerance = 25;

    function generateMetadata(uint256 tokenId, uint8 rectsWanted) public view returns (string memory)
    {        
        Rect[] memory rectangles = generateRectangles(tokenId, rectsWanted, 500, 500);
        bytes memory svgBytes = generateSVG(rectangles);

        Traits memory traits = calculateTraits(rectangles);
        string memory json =  Base64.encode(abi.encodePacked('{"name":"Mondrian puzzle #', uint2str(tokenId) ,'", "description":"A randomly generated and colorful Mondrian Puzzle, fully generated and stored on the chain.","image": "data:image/svg+xml;base64,', Base64.encode(svgBytes), '", "attributes": [ { "trait_type": "Mondrian Score", "value": "', uint2str(traits.score), '" },{ "trait_type": "Dominant color", "value": "', traits.dominantColor, '"},{ "trait_type": "Rectangles used", "value":"', uint2str(traits.rectangles), '" } ]}'));

        return json;
    }


    function generateSVG(Rect[] memory rectangles) private pure returns (bytes memory)
    {
        string memory svg_header = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' xmlns:v='https://vecta.io/nano' width='", uint2str(rectangles[0].width), "' height='", uint2str(rectangles[0].height), "' stroke-width='5' stroke='black' >"));
        string memory svg_tail = "</svg>";

                
        bytes memory output;
        
        for(uint16 i = 0; i < rectangles.length; i ++)
        {
            if(rectangles[i].x == 0 && rectangles[i].y == 0 && rectangles[i].width == 0 &&rectangles[i].height == 0)
                continue;
            
            bytes memory svg_rect = abi.encodePacked("<rect x='", uint2str(rectangles[i].x), "' y='", uint2str(rectangles[i].y), "' width='", uint2str(rectangles[i].width), "' height='", uint2str(rectangles[i].height), "' fill='", stringFromColor(rectangles[i].color), """' />" );
            output = abi.encodePacked(output, svg_rect);
            
        }
        return abi.encodePacked(svg_header, output, svg_tail);        
    }

    function calculateTraits(Rect[] memory rectangles) private pure returns (Traits memory)
    {
        uint256 small = (rectangles[0].width/denominator) * (rectangles[0].height/denominator);
        uint256 large = 0;
        //uint16 count = 0;
        
        uint256[] memory colorsUsed = new uint256[](5);

        for(uint8 i = 1; i < rectangles.length; i++)
        {
            if(rectangles[i].width == 0 || rectangles[i].height == 0)
                continue;
            
            uint256 area = (rectangles[i].width/denominator) * (rectangles[i].height/denominator);
            colorsUsed[uint8(rectangles[i].color)] += area;

            //count++;
            if(area < small){
                small = area;
                continue;
            }
            if(area > large){
                large = area;
                continue;
            }            
        }

        Color dColor = Color.red; //0
        for(uint8 i = 1; i < colorsUsed.length;i++)
        {
            if(colorsUsed[i] > colorsUsed[uint(dColor)])
                dColor = Color(i);
        }
        return Traits({score: large-small, dominantColor: stringFromColor(dColor), rectangles: rectangles.length-1 });
    }

    function generateRectangles(uint256 tokenId, uint8 wantedRects, uint16 canvas_width, uint16 canvas_height) private view returns (Rect[] memory)
    {

        Color[13] memory colors = [Color.red, Color.red, Color.red, Color.blue, Color.blue, Color.blue, Color.white, Color.white, Color.white, Color.yellow, Color.yellow, Color.yellow, Color.black];
        Rect[] memory rectangles = new Rect[](wantedRects+1);
        uint16 counter = 0;
        uint16 probability = 5;
        uint256 seed = (tokenId**wantedRects) ;
        uint8 numerator = uint8(denominator)/(wantedRects/2);        
        
        Rect memory availableRect = Rect({ x:0, y:0, width: canvas_width, height:canvas_height, color: Color.white });
        Rect memory newRect;

        rectangles[counter++] = availableRect;

        while (counter < rectangles.length && (availableRect.width >= tolerance && availableRect.height >= tolerance))
        {
            seed += counter;            
            uint fraction = (random(seed) % numerator) +1; 
            
            Color newColor = colors[random(seed) % colors.length];                
            while (newColor == availableRect.color )
                newColor = colors[random(++seed) % colors.length];
 
            if((random(seed) % 10) > probability) //Vertical 
            {
                probability = probability+2;
                uint new_width = (canvas_width * fraction) / denominator;
                                
                while(new_width >= availableRect.width)
                {
                    fraction = (random(++seed) % numerator) + 1;
                    new_width = (canvas_width * fraction) / denominator;
                }

                uint newX = availableRect.x;
                uint deltaX = availableRect.x + new_width;
                if((random(++seed) % 10) >= 5 ){
                    newX = availableRect.width + availableRect.x - new_width;
                    deltaX = availableRect.x;
                }

                newRect = Rect({x: newX, y: availableRect.y, width: new_width, height: availableRect.height, color: newColor});
                rectangles[counter++] = newRect;
                availableRect = Rect({x: deltaX, y: availableRect.y, width: availableRect.width - newRect.width, height: availableRect.height, color: newRect.color});
            }
            else //Horizontal
            {
                if(probability > 2)
                    probability = probability - 2;

                uint new_height = (canvas_height * fraction) / denominator;

                while(new_height >= availableRect.height)
                {
                    fraction = (random(++seed)% numerator) +1;
                    new_height = (canvas_height * fraction) / denominator;
                }        

                uint newY = availableRect.y;
                uint deltaY = availableRect.y + new_height;
                if((random(++seed) % 10) < 5){
                    newY = availableRect.height + availableRect.y - new_height;
                    deltaY = availableRect.y;
                }

                newRect = Rect({x: availableRect.x, y: newY, width: availableRect.width, height: new_height, color: newColor});
                rectangles[counter++] = newRect;
                availableRect = Rect({x: availableRect.x, y: deltaY, width: availableRect.width, height: availableRect.height-new_height, color: newRect.color});
            }
        }            
        return rectangles;
    }


    function random(uint seed) public view returns (uint) {
        return uint(keccak256(abi.encodePacked( block.difficulty, seed)));
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function uint2str(uint _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function stringFromColor(Color color) private pure returns (string memory) {
        if(color == Color.red)
            return "red";
        else if(color == Color.blue)
            return "blue";
        else if(color == Color.white)
            return "white";
        else if(color == Color.yellow)
            return "yellow";
        else if(color == Color.black)
            return "black";
        else
            return "green";
    }
}