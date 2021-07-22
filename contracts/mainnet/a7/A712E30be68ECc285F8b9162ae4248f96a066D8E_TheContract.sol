/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

// SPDX-License-Identifier: ART

pragma solidity ^0.8.0;

//
//  ████████╗██╗  ██╗███████╗                                            
//  ╚══██╔══╝██║  ██║██╔════╝                                            
//     ██║   ███████║█████╗                                              
//     ██║   ██╔══██║██╔══╝                                              
//     ██║   ██║  ██║███████╗                                            
//     ╚═╝   ╚═╝  ╚═╝╚══════╝                                            
//                                                                       
//   ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  █████╗  ██████╗████████╗
//  ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
//  ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝███████║██║        ██║   
//  ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██╔══██║██║        ██║   
//  ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║  ██║╚██████╗   ██║   
//   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   
//           __                                       
//  |_  \/   |_  o     o __  _|   |/  |  _  o     _ __ 
//  |_) /    |__ | \_/ | | |(_|   |\  | (/_ | \_/(/_| |                                                                                  
//                                                                                 
//                                                                                 
// @title The Contract by Eivind Kleiven
// @author Eivind Kleiven
// The Contract is a Non-Fungible Token contract.
// The contract itself is the creation and token holder is it's owner.
// The contract is a homage to Fade by Pak: 0x62F5418d9Edbc13b7E07A15e095D7228cD9386c5


contract TheContract { 

    using Strings for uint256;
    
    using Strings for uint8;

    // Artist
    string public artist = "Eivind Kleiven";
    
    // 10% Royalty is paid to this account on every sale
    address payable private _artistAccount = payable(0x85c0C90946E3e959f537D01CEBd93f97C9B5E372);

    // Token name
    string public name = "The Contract";
    
    // Token symbol
    string public symbol = "THECONTRACT";
    
    // Contract and token owner
    address public owner;
    
    // Approved address
    address private _tokenApproval;

    // Operator approvals
    mapping (address => bool) private _operatorApprovals;
    
    // Supported interfaces
    mapping(bytes4 => bool) private _supportedInterfaces;
    
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    

    // @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // SVG parts used to build SVG and url escaped svg strings
    string[57] private _svgParts;

    /**
     * @dev Initializes the contract by setting message sender as token/contract `owner`.
     */
    constructor () {
        owner = msg.sender;
        
        
        _supportedInterfaces[_INTERFACE_ID_ERC165] = true;
        _supportedInterfaces[_INTERFACE_ID_ERC721] = true;
        _supportedInterfaces[_INTERFACE_ID_ERC721_METADATA] = true;
        _supportedInterfaces[_INTERFACE_ID_ERC721_ENUMERABLE] = true;
        _supportedInterfaces[_INTERFACE_ID_ERC2981] = true;

        _svgParts[0]="<svg xmlns='http://www.w3.org/2000/svg' id='TheContractByEivindKleiven' viewBox='0 0 ";
        _svgParts[1]="%3Csvg%20xmlns%3D%27http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%27%20id%3D%27TheContractByEivindKleiven%27%20viewBox%3D%270%200%20";
        _svgParts[2]="%253Csvg%2520xmlns%253D%2527http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg%2527%2520id%253D%2527TheContractByEivindKleiven%2527%2520viewBox%253D%25270%25200%2520";
        _svgParts[3]=" ";
        _svgParts[4]="%20";
        _svgParts[5]="%2520";
        _svgParts[6]="' shape-rendering='crispEdges' style='background-color: #ffffff;'><clipPath id='TheContractClipPath'><rect x='0' y='0' width='100' height='100'/></clipPath><defs><filter id='TheContractFilter'><feColorMatrix type='matrix' values=' 1.430 -0.639 -1.920 0.000 0.934 -0.852 -0.604 0.328 0.000 0.934 0.876 -3.300 1.290 0.000 0.934 0.000 0.000 0.000 1.000 0.000'/><feColorMatrix type='hueRotate' values='0'><animate attributeName='values' values='0; 360; 0' calcMode='spline' keySplines='0.4 0 0.2 1; 0.4 0 0.2 1' dur='30s' repeatCount='indefinite' /></feColorMatrix></filter>";
        _svgParts[7]="%27%20shape-rendering%3D%27crispEdges%27%20style%3D%27background-color%3A%20%23ffffff%3B%27>%3CclipPath%20id%3D%27TheContractClipPath%27>%3Crect%20x%3D%270%27%20y%3D%270%27%20width%3D%27100%27%20height%3D%27100%27%2F>%3C%2FclipPath>%3Cdefs>%3Cfilter%20id%3D%27TheContractFilter%27>%3CfeColorMatrix%20type%3D%27matrix%27%20values%3D%27%201.430%20-0.639%20-1.920%200.000%200.934%20-0.852%20-0.604%200.328%200.000%200.934%200.876%20-3.300%201.290%200.000%200.934%200.000%200.000%200.000%201.000%200.000%27%2F>%3CfeColorMatrix%20type%3D%27hueRotate%27%20values%3D%270%27>%3Canimate%20attributeName%3D%27values%27%20values%3D%270%3B%20360%3B%200%27%20calcMode%3D%27spline%27%20keySplines%3D%270.4%200%200.2%201%3B%200.4%200%200.2%201%27%20dur%3D%2730s%27%20repeatCount%3D%27indefinite%27%20%2F>%3C%2FfeColorMatrix>%3C%2Ffilter>";
        _svgParts[8]="%2527%2520shape-rendering%253D%2527crispEdges%2527%2520style%253D%2527background-color%253A%2520%2523ffffff%253B%2527>%253CclipPath%2520id%253D%2527TheContractClipPath%2527>%253Crect%2520x%253D%25270%2527%2520y%253D%25270%2527%2520width%253D%2527100%2527%2520height%253D%2527100%2527%252F>%253C%252FclipPath>%253Cdefs>%253Cfilter%2520id%253D%2527TheContractFilter%2527>%253CfeColorMatrix%2520type%253D%2527matrix%2527%2520values%253D%2527%25201.430%2520-0.639%2520-1.920%25200.000%25200.934%2520-0.852%2520-0.604%25200.328%25200.000%25200.934%25200.876%2520-3.300%25201.290%25200.000%25200.934%25200.000%25200.000%25200.000%25201.000%25200.000%2527%252F>%253CfeColorMatrix%2520type%253D%2527hueRotate%2527%2520values%253D%25270%2527>%253Canimate%2520attributeName%253D%2527values%2527%2520values%253D%25270%253B%2520360%253B%25200%2527%2520calcMode%253D%2527spline%2527%2520keySplines%253D%25270.4%25200%25200.2%25201%253B%25200.4%25200%25200.2%25201%2527%2520dur%253D%252730s%2527%2520repeatCount%253D%2527indefinite%2527%2520%252F>%253C%252FfeColorMatrix>%253C%252Ffilter>";
        _svgParts[9]="<linearGradient id='TheContractGradient' x1='0' x2='0' y1='0' y2='1'><stop offset='0%' stop-color='#";
        _svgParts[10]="%3ClinearGradient%20id%3D%27TheContractGradient%27%20x1%3D%270%27%20x2%3D%270%27%20y1%3D%270%27%20y2%3D%271%27>%3Cstop%20offset%3D%270%25%27%20stop-color%3D%27%23";
        _svgParts[11]="%253ClinearGradient%2520id%253D%2527TheContractGradient%2527%2520x1%253D%25270%2527%2520x2%253D%25270%2527%2520y1%253D%25270%2527%2520y2%253D%25271%2527>%253Cstop%2520offset%253D%25270%2525%2527%2520stop-color%253D%2527%2523";
        _svgParts[12]="'/><stop offset='50%' stop-color='#";
        _svgParts[13]="%27%2F>%3Cstop%20offset%3D%2750%25%27%20stop-color%3D%27%23";
        _svgParts[14]="%2527%252F>%253Cstop%2520offset%253D%252750%2525%2527%2520stop-color%253D%2527%2523";
        _svgParts[15]="'/><stop offset='100%' stop-color='#";
        _svgParts[16]="%27%2F>%3Cstop%20offset%3D%27100%25%27%20stop-color%3D%27%23";
        _svgParts[17]="%2527%252F>%253Cstop%2520offset%253D%2527100%2525%2527%2520stop-color%253D%2527%2523";
        _svgParts[18]="'/></linearGradient>";
        _svgParts[19]="%27%2F>%3C%2FlinearGradient>";
        _svgParts[20]="%2527%252F>%253C%252FlinearGradient>";
        _svgParts[21]="</defs><g filter='url(#TheContractFilter)' clip-path='url(#TheContractClipPath)'><circle cx='50' cy='50' r='71' fill='url(#TheContractGradient)' fill-opacity='20%'><animateTransform attributeName='transform' type='rotate' from='0 50 50' to='360 50 50' dur='60s' repeatCount='indefinite' /></circle>";
        _svgParts[22]="%3C%2Fdefs>%3Cg%20filter%3D%27url%28%23TheContractFilter%29%27%20clip-path%3D%27url%28%23TheContractClipPath%29%27>%3Ccircle%20cx%3D%2750%27%20cy%3D%2750%27%20r%3D%2771%27%20fill%3D%27url%28%23TheContractGradient%29%27%20fill-opacity%3D%2720%25%27>%3CanimateTransform%20attributeName%3D%27transform%27%20type%3D%27rotate%27%20from%3D%270%2050%2050%27%20to%3D%27360%2050%2050%27%20dur%3D%2760s%27%20repeatCount%3D%27indefinite%27%20%2F>%3C%2Fcircle>";
        _svgParts[23]="%253C%252Fdefs>%253Cg%2520filter%253D%2527url%2528%2523TheContractFilter%2529%2527%2520clip-path%253D%2527url%2528%2523TheContractClipPath%2529%2527>%253Ccircle%2520cx%253D%252750%2527%2520cy%253D%252750%2527%2520r%253D%252771%2527%2520fill%253D%2527url%2528%2523TheContractGradient%2529%2527%2520fill-opacity%253D%252720%2525%2527>%253CanimateTransform%2520attributeName%253D%2527transform%2527%2520type%253D%2527rotate%2527%2520from%253D%25270%252050%252050%2527%2520to%253D%2527360%252050%252050%2527%2520dur%253D%252760s%2527%2520repeatCount%253D%2527indefinite%2527%2520%252F>%253C%252Fcircle>";
        _svgParts[24]="<circle fill='#";
        _svgParts[25]="%3Ccircle%20fill%3D%27%23";
        _svgParts[26]="%253Ccircle%2520fill%253D%2527%2523";
        _svgParts[27]="' cx='";
        _svgParts[28]="%27%20cx%3D%27";
        _svgParts[29]="%2527%2520cx%253D%2527";
        _svgParts[30]="' cy='";
        _svgParts[31]="%27%20cy%3D%27";
        _svgParts[32]="%2527%2520cy%253D%2527";
        _svgParts[33]="' r='4' />";
        _svgParts[34]="%27%20r%3D%274%27%20%2F>";
        _svgParts[35]="%2527%2520r%253D%25274%2527%2520%252F>";
        _svgParts[36]="</g>";
        _svgParts[37]="%3C%2Fg>";
        _svgParts[38]="%253C%252Fg>";
        _svgParts[39]="<text x='";
        _svgParts[40]="%3Ctext%20x%3D%27";
        _svgParts[41]="%253Ctext%2520x%253D%2527";
        _svgParts[42]=".75' y='";
        _svgParts[43]=".75%27%20y%3D%27";
        _svgParts[44]=".75%2527%2520y%253D%2527";
        _svgParts[45]="' fill='#ffffff' font-size='6px'>";
        _svgParts[46]="%27%20fill%3D%27%23ffffff%27%20font-size%3D%276px%27>";
        _svgParts[47]="%2527%2520fill%253D%2527%2523ffffff%2527%2520font-size%253D%25276px%2527>";
        _svgParts[48]="</text>";
        _svgParts[49]="%3C%2Ftext>";
        _svgParts[50]="%253C%252Ftext>";
        _svgParts[51]="</svg>";
        _svgParts[52]="%3C%2Fsvg>";
        _svgParts[53]="%253C%252Fsvg>";
        _svgParts[54]="<g><animate attributeName='fill-opacity' values='1;0;1;1' dur='1s' repeatCount='indefinite'/>";
        _svgParts[55]="%3Cg>%3Canimate%20attributeName%3D%27fill-opacity%27%20values%3D%271%3B0%3B1%3B1%27%20dur%3D%271s%27%20repeatCount%3D%27indefinite%27%2F>";
        _svgParts[56]="%253Cg>%253Canimate%2520attributeName%253D%2527fill-opacity%2527%2520values%253D%25271%253B0%253B1%253B1%2527%2520dur%253D%25271s%2527%2520repeatCount%253D%2527indefinite%2527%252F>";
               
        emit Transfer(address(0), msg.sender, 1);
    }
    
 
    function setArtistAccount(address artistAccount) public {
        require(msg.sender == _artistAccount, "Only current artist account may change artist account");
        _artistAccount = payable(artistAccount);
    }

    function generateSvg(uint8 urlEncodePasses) public view returns (string memory){
        require(urlEncodePasses < 3, "Not possible to url encode more than two passes");
        
        bytes memory b = getContractBytecode();
        
        uint maximumNumberOfPixels = b.length/3;
        uint rows = 10;
        uint displayNumberOfPixels = rows*rows;
        

        uint startAt = (displayNumberOfPixels*block.number) % (maximumNumberOfPixels - displayNumberOfPixels);
        uint endAt = startAt + displayNumberOfPixels;
        
        
        bytes memory data =  abi.encodePacked(_svgParts[urlEncodePasses], (rows*10).toString(), _svgParts[3 + urlEncodePasses], (rows*10).toString(), _svgParts[6 + urlEncodePasses], generateLinearGradient(urlEncodePasses), _svgParts[21+urlEncodePasses]);

        
        uint lastBlinkIndex = 0;
        if(hasBid && bid >= 1 ether){
            data = abi.encodePacked(data, _svgParts[54 + urlEncodePasses]);
            lastBlinkIndex = startAt + bid / 1000000000000000000;
        }
        
        for (uint i = startAt; i < endAt; i++)
        {
            
            if(lastBlinkIndex > 0 && i == lastBlinkIndex){
                data = abi.encodePacked(data, _svgParts[36 + urlEncodePasses]);
            }
            
            bytes memory hexColor = abi.encodePacked(uint8(b[3*i]).toHexString(), uint8(b[3*i+1]).toHexString(), uint8(b[3*i+2]).toHexString());
            data = abi.encodePacked(data, _circleElement(urlEncodePasses, hexColor, (((i-startAt) % rows)*10+5).toString(), (10*((i-startAt) / rows)+5).toString()));
   
        }
        
        if(lastBlinkIndex >= endAt){
            data = abi.encodePacked(data, _svgParts[36 + urlEncodePasses]);
        }     
        
    
        return string(abi.encodePacked(data, _svgParts[36 + urlEncodePasses], generateBlockNumberElements(urlEncodePasses), _svgParts[51 + urlEncodePasses]));
    }
    
    function _circleElement(uint8 urlEncodePasses, bytes memory hexColor, string memory cx, string memory cy) private view returns (bytes memory){
        return abi.encodePacked(_svgParts[24 + urlEncodePasses], hexColor, _svgParts[27 + urlEncodePasses], cx, _svgParts[30 + urlEncodePasses], cy, _svgParts[33 + urlEncodePasses]);
    }
    
    
    
    
    function generateLinearGradient(uint8 urlEncodePasses) internal view returns (string memory){
        
        bytes memory ownerBytes = abi.encodePacked(owner);
        
        bytes memory hexColor1 = abi.encodePacked(uint8(ownerBytes[0]).toHexString(),uint8(ownerBytes[1]).toHexString(),uint8(ownerBytes[2]).toHexString()); 
        bytes memory hexColor2 = abi.encodePacked(uint8(ownerBytes[3]).toHexString(),uint8(ownerBytes[4]).toHexString(),uint8(ownerBytes[5]).toHexString()); 
        bytes memory hexColor3 = abi.encodePacked(uint8(ownerBytes[6]).toHexString(),uint8(ownerBytes[7]).toHexString(),uint8(ownerBytes[8]).toHexString()); 
        
        return string(abi.encodePacked(_svgParts[9+urlEncodePasses], hexColor1, _svgParts[12+urlEncodePasses], hexColor2, _svgParts[15+urlEncodePasses],hexColor3,  _svgParts[18+urlEncodePasses]));
    }
        
    function generateBlockNumberElements(uint8 urlEncodePasses) internal view returns (string memory){
        
        bytes memory blockNumber = bytes(block.number.toString());
         
        uint8 x=93;
        uint8 y=97;
        bytes memory data;
        for(uint i = blockNumber.length; i > 0; i--)
        {
            data =  abi.encodePacked(data, _svgParts[39 + urlEncodePasses],x.toString(),_svgParts[42 + urlEncodePasses],y.toString(),_svgParts[45 + urlEncodePasses],blockNumber[i-1],_svgParts[48 + urlEncodePasses]);
            
            x=x-10;
            
            if(x < 3){
                x=93;
                y=y-10;
            }
       }
        return string(data);
    }
    
    
    function contentType() public pure returns (string memory){
        return "image/svg+xml";
    }
    
    function svg() public view returns (string memory){
        return generateSvg(0);
    }
    function svgDataURI() public view returns (string memory){
        return string(abi.encodePacked("data:", contentType(),",",generateSvg(1)));
    }
    
    
    function getContractBytecode() public view returns (bytes memory o_code) {
        
        address contractAddress =  address(this);
        
        assembly {
            
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(contractAddress)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(contractAddress, add(o_code, 0x20), 0, size)
        }
    }
    
    
    // Implementation of supportsInterface as defined in ERC165 standard
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
  
    // Total token supply.  
    function totalSupply() public pure returns (uint256) {
        return 1;
    }
    
    // Token by index of all tokens
    function tokenByIndex(uint256 index) public pure returns (uint256) {
        require(index == 0,"Index out of bound");
        return 1;
    }

    // Token by index of owners tokens    
    function tokenOfOwnerByIndex(address owner_, uint256 index) public view returns (uint256) {
        require(index == 0 && owner == owner_,"Index out of bound");
        return 1;
    }
    
    // Token uri to creation metadata
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "tokenURI query for nonexistent token");
        return string(abi.encodePacked(
                'data:application/json;charset=utf-8,{%22name%22%3A%22The%20Contract%22%2C%20%22description%22%3A%22The%20Contract%20is%20a%20Non-Fungible%20Token%20contract%20and%20the%20contract%20itself%20is%20the%20creation.%20Token%20holder%20is%20its%20owner.%20The%20contract%20is%20a%20homage%20to%20Fade%20by%20Pak%3A%200x62F5418d9Edbc13b7E07A15e095D7228cD9386c5%22%2C%22created_by%22%3A%22Eivind%20Kleiven%22%2C%22image_data%22%3A%22',generateSvg(1),'%22}'
            ));
    }
    
    // @return number of tokens held by owner_
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "Balance query for the zero address");
        return owner_ == owner ? 1 : 0;
    }

    // @return owner of tokenId
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Owner query for nonexistent token");
        return owner;
    }

    // Approve to for tokenId. Be aware that an approved address are allowed to transfer tokenId.
    function approve(address to, uint256 tokenId) public {
        require(_exists(tokenId), "Approve query for nonexistent token");
        require(to != owner, "Approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    // @return tokenId approved address.
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "getApproved query for nonexistent token");
        return _tokenApproval;
    }

    // Set approval for all. Be aware that if approval is set to true, then operator may transfer tokenId.
    function setApprovalForAll(address operator, bool approved) public {
        require(owner == msg.sender, "Only owner can set approval for all");
        require(operator != msg.sender, "Approve to caller");

        _operatorApprovals[operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    // @return approval boolean for an owner operator.
    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        if(owner_ == owner){
            return _operatorApprovals[operator];
        }
        
        return false;
    }


    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    
    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(_exists(tokenId), "Transfer of nonexistent token");
        require(owner == from, "Transfer of token that is not own");
        require(to != address(0), "Transfer to the zero address. Burn instead.");

        _approve(address(0), tokenId);
        _removeOffer();

        owner = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (tokenId == 1 && owner != address(0));
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "Operator query for nonexistent token");
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) public {
        require(_exists(tokenId),"Try to burn nonexistent token.");

        // Clear approvals
        _approve(address(0), tokenId);
 
        owner = address(0);
        
        _removeOffer();
        
        if(bid > 0){
            uint amount = bid;
            payable(bidder).transfer(amount);
            _resetBid();
        }
        
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApproval = to;
        emit Approval(owner, to, tokenId);
    }
    
    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(to) }
        
        if (size > 0) {
            
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    
    function destruct() public {
        require(msg.sender == owner, "Only owner can destruct contract.");
      
        if(bid > 0){
            payable(bidder).transfer(bid);
            _resetBid();
        }
        
        selfdestruct(payable(msg.sender));
    }
    
    
    
     // ENTER MARKETPLACE

    event Offered(uint indexed price, address indexed offeredTo);
    event RecievedBid(uint indexed value, address indexed bidder);
    event WithdrawnBid(uint indexed value, address indexed bidder);
    event Sold(uint indexed price, address indexed seller, address indexed buyer);
    event OfferRemoved();


    bool public hasBid;
    uint public bid;
    address public bidder;

    
    uint public offer;
    bool public isForSale;
    address public onlySellTo;
    address public seller;

    function _removeOffer() internal {
        isForSale = false;
        offer = 0;
        seller = address(0);
        onlySellTo = address(0);
    }
    
    function _resetBid() internal {
        hasBid=false;
        bid=0;
        bidder=address(0);
    }

    function removeOffer() public {
        require(owner == msg.sender, "Only owner can remove offer.");
        _removeOffer();
        emit OfferRemoved();
    }

    function offerForSale(uint priceInWei) public {
        require(owner == msg.sender, "Only owner can offer for sale.");
        offerForSaleToAddress(priceInWei, address(0));
    }
    
    function offerForSaleToAddress(uint priceInWei, address toAddress) public {
        require(owner == msg.sender, "Only owner can offer for sale.");
        require(priceInWei > 0, "Cannot offer for free.");
        
        offer = priceInWei;
        seller = msg.sender;
        onlySellTo = toAddress;
        isForSale = true;
        emit Offered(priceInWei, toAddress);
    }


    function buy() payable public {
        require(isForSale, "The Contract is not offered to buy.");
        require(onlySellTo == address(0) || onlySellTo == msg.sender,"Not offered to this buyer.");
        require(msg.value >= offer, "Sent less than offer.");
        require(seller == owner, "Only owner allowed to sell.");
    
        address payable beneficiary = payable(seller);
 

        _safeTransfer(seller, msg.sender, 1, "");

        uint amountToArtist = msg.value/10;
        if(amountToArtist > 0){
            _artistAccount.transfer(amountToArtist);
        }
        
        if(amountToArtist < msg.value)
        {

            beneficiary.transfer(msg.value - amountToArtist);
        }
        
        emit Sold(msg.value, seller, msg.sender);
        
    }
    
    
     function enterBid() public payable {
        require(_exists(1), "Nothing exist to bid on");
        require(owner != msg.sender, "Owner cannot bid");
        require(msg.value > bid, "Not allowed to bid less than current bid");

        address payable currentBidder = payable(bidder);
        uint currentBid = bid;
        
        hasBid = true;
        bidder = msg.sender;
        bid = msg.value;
        
        if (currentBid > 0) {
            // Refund previous bid
            currentBidder.transfer(currentBid);
        }
        
        emit RecievedBid(msg.value, msg.sender);
    }
    
    
    function acceptBid(uint minPrice) public {
        require(owner == msg.sender, "Only owner can accept bid.");
        require(bid >= minPrice, "Bid lower than given minimum price");

        uint amount = bid;
        address payable beneficiary = payable(owner);
            
        _safeTransfer(msg.sender, bidder, 1, "");

    
        emit Sold(amount, msg.sender, bidder);
        
        _resetBid();
        
        
        uint amountToArtist = amount/10;
        if(amountToArtist > 0){
            _artistAccount.transfer(amountToArtist);
        }
        
        if(amountToArtist < amount)
        {

            beneficiary.transfer(amount - amountToArtist);
        }

    
        
    }


  function withdrawBid() public {
        require(bidder == msg.sender, "Only bidder can withdraw bid");
        
        uint amount = bid;
        address payable beneficiary = payable(bidder);
        
        emit WithdrawnBid(bid, msg.sender);
        
        _resetBid();

        beneficiary.transfer(amount);
    }


    /// LEAVE MARKETPLACE
    
    
    
    /// BEGIN NFT Royalty Standard (ERC-2981)
    
    
    /** 
     * @notice Called with the sale price to determine how much royalty
     * is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     * 
     **/
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address,
        uint256
    ){
        require(_exists(_tokenId), "query for RoyaltyInfo for nonexistent tokenId");
        
        return (_artistAccount, _salePrice/10);

        
    }
    
    /**
     * @dev Returns true if implemented
     * 
     * @dev this is how the marketplace can see if the contract has royalties, other than using the supportsInterface() call.
     */
    function hasRoyalties() external pure returns (bool){
        return true;
    }

     /**
     * @dev Returns uint256 of the amount of percentage the royalty is set to. For example, if 1%, would return "1", if 50%, would return "50"
     * 
     */
    function royaltyAmount() external pure returns (uint256){
        return 10;
    }
    
    
    /// END NFT Royalty Standard (ERC-2981)
    
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    
     /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint8 value) internal pure returns (string memory) {
        
        if (value == 0) {
            return "00";
        }
        
        bytes memory buffer = new bytes(2);

        buffer[1] = _HEX_SYMBOLS[value & 0xf];
        value >>= 4;
        buffer[0] = _HEX_SYMBOLS[value & 0xf];


        return string(buffer);
    }
    
    

}