/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

contract BorgGeneFactory{
    struct Image{
        bool exists;
        string[] colors;
        int colorSize;
        mapping (string => uint256[]) colorPositions;
    }
    
    mapping (string => Image) _images;

    constructor(){}
    
    function addColorToImage(string memory imageName, string memory color, uint256[] memory positions) public{
         Image storage image = _images[imageName];
         image.colors.push(color);
         image.colorSize = image.colorSize + 1;
         image.colorPositions[color] = positions;
         image.exists = true;
    }
    
    function getImage(string memory imageName, uint256 expectedSize) public view returns (string[] memory imagePixals){
        Image storage image = _images[imageName];
        require(image.exists, "Image doesn't exist");
        
        imagePixals = new string[](expectedSize);
        
        for(uint256 i = 0;i<image.colors.length;i++){
            string memory color = image.colors[i];
            uint256[] memory positions = image.colorPositions[color];
            for(uint256 j = 0;j<positions.length;j++){
                imagePixals[positions[j]] = color;
            }
        }
        
        return imagePixals;
    }
    
    function combineImages(string[] memory imageNames, uint256 expectedSize) public view returns (string[] memory imagePixals){
        
        imagePixals = new string[](expectedSize);
        
        for(uint256 i=0;i<imageNames.length;i++){
             Image storage image = _images[imageNames[i]];
             require(image.exists, "Image doesn't exist");
             
             for(uint256 j = 0;j<image.colors.length;j++){
                string memory color = image.colors[j];
                uint256[] memory positions = image.colorPositions[color];
                for(uint256 k = 0;k<positions.length;k++){
                    imagePixals[positions[k]] = color;
                }
            }
        }
 
        return imagePixals;
    }
}