// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC721.sol"; 
import "./InventoryManager.sol";

//███████╗████████╗██╗░░██╗███████╗██████╗░███╗░░██╗░█████╗░██╗░░░░░███████╗██╗░░░░░██╗░░░██╗███████╗░██████╗
//██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗████╗░██║██╔══██╗██║░░░░░██╔════╝██║░░░░░██║░░░██║██╔════╝██╔════╝
//█████╗░░░░░██║░░░███████║█████╗░░██████╔╝██╔██╗██║███████║██║░░░░░█████╗░░██║░░░░░╚██╗░██╔╝█████╗░░╚█████╗░
//██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗██║╚████║██╔══██║██║░░░░░██╔══╝░░██║░░░░░░╚████╔╝░██╔══╝░░░╚═══██╗
//███████╗░░░██║░░░██║░░██║███████╗██║░░██║██║░╚███║██║░░██║███████╗███████╗███████╗░░╚██╔╝░░███████╗██████╔╝
//╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝░░░╚═╝░░░╚══════╝╚═════╝░


interface MetadataHandlerLike {
    function getTokenURI(uint16 id) external view returns (string memory);
}

contract EthernalElves is ERC721 {

    /*///////////////////////////////////////////////////////////////
    Alas, I am the Ethernal Elves. I am the one who created this. Fear me
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return "Ethernal Elves";
    }

    function symbol() external pure returns (string memory) {
        return "ELV";
    }

    ERC20 public ren;
    
    
    mapping (uint256 => Elf)      public elves;
    struct Elf { uint8 body; uint8 helm; uint8 mainhand; uint8 offhand; uint16 level; uint16 zugModifier; uint32 lvlProgress; }
    bytes32 internal entropySauce;
    MetadataHandlerLike metadaHandler;

    function initialize() public onlyOwner {

       ren = ERC20(0x577E3D35F573688Bb93e4E395171A54fc617f0c7);
       
    }
    
    function _getMintingPrice() internal view returns (uint256) {

        if (supply < 2222) return   .055 ether;
        if (supply < 3333) return   60 ether;
        if (supply < 4444) return   80 ether;
        if (supply < 5555) return  160 ether;
        if (supply < 6666) return  180 ether;
        if (supply < 7167) return  360 ether;
        if (supply < 7667) return  760 ether;
        if (supply < 8167) return  760 ether;
        if (supply < 8667) return  780 ether;
        if (supply < 8888) return 2000 ether;
    }

    function mint() public noCheaters returns (uint256 id) {
    
        uint256 cost = _getMintingPrice();
        uint256 rand = _rand();
        require(address(ren) != address(0));

        if (cost > 0) ren.burn(msg.sender, cost);

        return _mintElf(rand);
    }


    function _mintElf(uint256 rand) internal returns (uint16 id) {

        (uint8 body,uint8 helm,uint8 mainhand,uint8 offhand) = (0,0,0,0);

        {
            // Helpers to get Percentages
            uint256 sevenOnePct   = type(uint16).max / 100 * 71;
            uint256 eightyPct     = type(uint16).max / 100 * 80;
            uint256 nineFivePct   = type(uint16).max / 100 * 95;
            uint256 nineNinePct   = type(uint16).max / 100 * 99;
    
            id = uint16(totalSupply + 1);
    
            // Getting Random traits
            uint16 randBody = uint16(_randomize(rand, "BODY", id));
                   body     = uint8(randBody > nineNinePct ? randBody % 3 + 25 : 
                              randBody > sevenOnePct  ? randBody % 12 + 13 : randBody % 13 + 1 );
    
            uint16 randHelm = uint16(_randomize(rand, "HELM", id));
                   helm     = uint8(randHelm < eightyPct ? 0 : randHelm % 4 + 5);
    
            uint16 randOffhand = uint16(_randomize(rand, "OFFHAND", id));
                   offhand     = uint8(randOffhand < eightyPct ? 0 : randOffhand % 4 + 5);
    
            uint16 randMainhand = uint16(_randomize(rand, "MAINHAND", id));
                   mainhand     = uint8(randMainhand < nineFivePct ? randMainhand % 4 + 1: randMainhand % 4 + 5);
        }

        _mint(msg.sender, id);

        uint16 zugModifier = _tier(helm) + _tier(mainhand) + _tier(offhand);
        elves[uint256(id)] = Elf({body: body, helm: helm, mainhand: mainhand, offhand: offhand, level: 0, lvlProgress: 0, zugModifier:zugModifier});
    }


    function tokenURI(uint256 id) external view returns(string memory) {
        Elf memory elf = elves[id];
        return metadaHandler.getTokenURI(uint16(id));
    }



    //////Utils/////
        modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require((msg.sender == tx.origin && size == 0), "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

        /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
    }

        /// @dev Convert an id to its tier
    function _tier(uint16 id) internal pure returns (uint16) {
        if (id == 0) return 0;
        return ((id - 1) / 4 );
    }
 
    
    
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20 is Ownable {

    string public constant name     = "MIREN";
    string public constant symbol   = "REN";
    uint8  public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isFed;

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }


    function mint(address to, uint256 value) external {
        require(isFed[msg.sender], "FORBIDDEN TO MINT");
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        require(isFed[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, value);
    }


    function setMinter(address minter, bool status) onlyOwner external {

        isFed[minter] = status;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721 is Ownable {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
      
    address        implementation_;
    
    uint16 public totalSupply;
    uint16 public counter;
    uint16 public supply;
    uint16 public minted;
    uint16 public maxSupply = 8888;
    
    mapping(address => uint256) public balanceOf;    
    mapping(uint256 => address) public ownerOf;        
    mapping(uint256 => address) public getApproved; 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        _transfer(msg.sender, to, tokenId);        
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner_ = ownerOf[tokenId];
        
        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner_, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address, address to, uint256 tokenId) public {
        address owner_ = ownerOf[tokenId];
        
        require(
            msg.sender == owner_ 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[owner_][msg.sender], 
            "NOT_APPROVED"
        );
        
        _transfer(owner_, to, tokenId);
        
    }
    
    function safeTransferFrom(address, address to, uint256 tokenId) external {
        safeTransferFrom(address(0), to, tokenId, "");
    }
    
    function safeTransferFrom(address, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(address(0), to, tokenId); 
        
        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), tokenId, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from);

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) onlyOwner internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
        supply = counter + minted;
        require(supply <= maxSupply, "MAX SUPPLY REACHED");
        totalSupply++;
                
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract InventoryManager {


    string public constant header = '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = '<style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';


    function getTokenURI(uint16 id_) public view returns (string memory) {

        string memory svg = Base64.encode(bytes("iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAADLRJREFUeJztWl9oW9cZ/11JUSw7lu1oleMkTWRD6qSucbziB9mMMdWkgzS4xQazBxPoQ8HtoKTxQ6HBJiaDMlxKYW0gDxkhT21tGs0TYyZoC8zRQ3BiE5zEzZBUmjSzXfmP5ESpIvnsQfqOzr333Kt/2dP6g4t0/53zfb/vz/nOORf4GT/j/xpKOS9ZXMOq8+3YedPnOzp7+X+31Z47dgIA7ifsqDl0GF9fe8BIpkLtPU9UQgADgDdeb1P++vdFHQmktNtqh3P3Tvx7NUEKwudwqZ79bGk3Ht4dx74jo3il7qny2p4nuj4/vf5lOaIWhK2Sl3NCMwhEdnT2otnmAABE0km2kknhla1atB1vNm5oKf/3tT1PmPa2td6qnOoe5OefXv+yZC80QkUEELxdHoRuDKP9wH24rXZE0knmc7jQvKMatT6n6tlEMA4AuusE2fVEMM5JsdZblTfah1BzaL8qbMqV3VLui4SHd8cRuhFlvb9qRFVNA1YyKeZzuFDrc6qUSQTjSATjuuvnztvw8O64tG2RLDoyGxl2qDbFvr72gBm9VwrK9gBvl0fZd2SUPbw7zkOh/cA6+o43c8EJpLiIc+ezXZMS+46M4sxwWvWMzBs+W9qteg8ADtWmsBQrT4+yPGA7dh6hG1EAWcG1AhUDIk5sQ0ucCLp3ZjjNE+a+I6N4v3UNnZ40xBxRCsqPHdcwanY+weOfqhkAtB+4r8vuBCPrizgznFYRUOtzqjxH60Xnztu4x+TeU8oZKUr2AItrmGfgmqok2g/c5/c+vv6N9J2Pzl3CR+cuSe+dGU7j/dY1AOpYp3MxD4gEacPFWm8tywvKzQEMAF49uk95EFnDmeE0/AHAzlL4WPkGfzhzEkDWMh9f/wZ2lsIHPYP4LGd5WazL8oQWWhI0RKmG42JR9ijw8O44/nbtKesTxvcPegbxYfdbKgE/7H4LH/QMcmEf3h3nISBLltprZkrL2igVFQ+DIoLJGGp9TvgDEQCAPxAxtarWxbVDpOy5543SXSZXBmszuJgLRIjDIpW84nuU/Aq5P2BcRAnkKEBpZXPZBADqoe+3r/8Ofceb4Q9E4HO4EEzGQAWRKKRIAgD88c3f6zyhGMhGDACwuW1KeiVdNAnlEgDkSCC0H7jPrS1LaqLAVMwQtEmxEiSC8ZJIKDkH0KRjn+OZlDxZkhKVDyZjunCR1QVTF+f5f8op1J4Zan1OpFfSzOa2FTUsljUMbsfOo6N9CAMHElxRf8BcuGAyW6tSseTLjf2EqYth9L99tBxxdKBhcc21rXR09mLh1lXDZ8ueCxyqTanOKf6NYFQlAlmB+3EUUxfniyKBwssfiOjmHqIHBgMR5rbaTUkoaxg81T0Ia72Vn5Pi6eVN9B1vRt/xZvgcLtUxEw3z52eiYemwR8obEWHkYWI74jM+hwsrmZRufUFE2XVAZiPDZBmbYrfW51QpLQqrfV57iMrLrAzIydCSQOf1FptqWU7Ec1kQIcisRkL0Q25dM5c3Up7yCSCfaovXc0OyYZlc8jBI7i96QCIYVwkllseiwuJ/Us4ob1AbpDx50zFPC/WlAGBirUHQTqCCyRjqLTZlYzutywUlecCp7kHY3DakV9I699cmOVKw/+2jPCxE5el5mYVFYmeiYRzztKiUJ2XcVrsSTMaYL2heQJl5QdE5wEx5IO+W9Ctat//to1LlRYXFg2oHUl4kAQDIkiuZFJFgSGIhFOUBRsqTZY95WnRKkbtrXdxsOJSRQ5iJhmFrrOPWB4CFW1fR0dnLPQGBPPnFoiABZpYnq2gtJELm4oC5hcR4F9sOJmPQxjGRgLx782FP1q+2JjAk4MpoFwDg+7U4wjedXHmyrNi4KOAeZ5XiD0RUY28x7kjWF5UXIca+FmdPbAIA/nF7F/4ZteruC9DlASkBV0a74KytRjzxhL24+0es+vbze8c8LSrXB/Lu6bbalf/En+rak02MjEghq8sgy+Kicr9p34JluYUb5933tgEAi0tR/BrA2HSd7iUdAaLyba2e7MWledzczltdtDgAuFz1yvpWEiu78u1Q9rc15joNaNatAzEe7yIZYuKjvsysL6Kt1YO21m3TZ7RQESBVPtcwluaBXjWLJNSmjeH2/X8BgK7iMsoBBKrpteUyKU4kF7A+AOBOu35Qe/m2OSGcgCujXcD+GsQfPFYpT2hr9WBxKbsX8MKujLK6ZdUJdap7ECuZn+Dab1H8gQijoa/YIUnrWRTbY9N18LjSgNnM7oUqhU2GmTLQUpTiBDVlDx4zZaAFl0MhwxfOntjE6paVAdApb3Pb4LbuZNZHO9jkSIPpPF57TtYPJmOYHGnA5EiDqs9ozMbamp5Ja/o3x28Aq+rcQ95wORTCzbVHRKKuEOIeEFV2wcO28PLtbbzs9epIGPJ65YxAP1SKyhnlAZ/DxctUn8MFeFxceYLodWdPbGJsuk46vb0y2gW8UKUigTxgyOvF4lIUfgPZOQF//ouVjV9qAYQXCQMT6xjyAjfXHuWu5PNAoQoRKFALBPIVpKg8AHzxuQVAfjj0OYBgMqYigUKXvHfuwiyXXTTi2RPA2HQda2t6pgB5AsV9fUYCDEysc2Euh0JIPm5VZuYVNn7JBTYZpkSo+BwuQ+UTwTjefW8bAxPrqspMOwRSmIjKZxU33CpHMBmD22pXVjIpyhOq2L8cCmHI61UlRTaZDTGSnQhQ5YDLoVBW4J57/LzR6VTmwkmdIG6rvaDlZdA+qy1bv/jcYrg/QO/LFjrYZJi7vX/2MAYm1rPhnLtGBAGAy5n/AkVFwKvv9Kh+AWDx+zT21GWFmbswq0omZsrX+pz44nMLzp7YVG2UiEciGIc/EOHWJ+VlEBdXxYWOyI9WruDiUhQDE+toabQqLY1WZWBiHQA4ETfXHqGv5x5i8WpOXsHZ4FbSjsXv02xypAG/3N0EAHiyUY0Dv6jRLUzIZmRj03WcBO1yWSkQZ4pANolubKdZNJYvZcjK4eUMwssZANnR4E67hYeFaFxAUwiRu8xdmMVc7trqRjWAbDk5Nl2HtqZnyuqKHc64hWndV2Y9n8OFsWnK4lkSVM/lkqDW+sVulERjNixaHMpXJ2PStb+5C7MAsmExJBnIuAf0dz9VKGu++k4Phrxe+GcPo646SwAp/2TVqbO+kaCitURPKAZaixv1s7Feha/8DMgmdDo4RKtfDoU4IQTuAWklihv39ioQppOTIw0YmFjnM6jFRzvgc1QDceisr4VWcPIEADoSKFZ9Qb2ipskwCL7So60QZQUTEeGfzRuPe8D4nx7gh5gTbV12ZfRkTFdXL9y6qitDjWp82XWa0EBtKX7UW2yKWPvLckqx6OjsRduLWduKtYCsPFblgKyCvUSCNKZWMj/xrzxlMFKexm2jWp4WNeotNgSTMUZJspSptNAOT9x32nswejJbZN1pt2D0ZAyewzZl4Vb2ed0osHDrKhZvpACDmFrJpLiVitm3J8ubKU/9Lty6CmGxU6U0ochvBRignh2KnhC9l59WSxdEzARdyai3xIx2gEUUM5UV+xbX+cw8wQyTIw24AwjWz3pCW5ddyRkYQAUbI6UKVArMSCgWlFhF1yflRWOUtTUmLkVXkqzMQMvelByNPp0BpFtfCgCl7UWbMjCxbqg8PVgyctbhn8VqMRMN84VTs12ZYvuCwQ4QoNqVKjgUyvovKwR06/EaiPt9tCvTbHMoC+V0BpAXFNwBkslZCGV/KQpIiw1eIIlfeBzztGAusaZs2ljFXkArR+KWW27BRecBxaAiAmRCppc3uYDixiYtmxcaDs3aFleRtRutKJOA5/qdIJDfB5y6OK9y12I+VpCho7MX9ZZspM5Ew4Z7Bq7dVYbfAJjhuRDQ0dkLlpKv2ZttmxWLje008zlcOOZp4RszYp7pO96M2NpTtv1UvmhqhooJ6Ojsxd6mGih2G0svb6pinwQ1s1ypqPU5uYdRX1MX55Fe3oSlagfb21RTEgkVfSFCyv/w6DEz+yhCu95fLmaiYeBi9r/R90T+QITtbapRLXyaoSQCZMxqlf9fgUKJEqARct8lMAAFP5EDSgiBjs5eeF/aAWQnGuLB1/joP+0DaK2fmw5XhEQwDltjHe+P/ov958C8L+0oGA5FEUDKh759xiZHGnCwuZHfE3dxaIHzYHMj/IGILvmVWw0C6m2zg82NEHeeSAY6p/uhb58VJKEgAVrlT0/Z8V1kmXcMAKen7CpSPulP4WBzo+qzGbfVXrH1SflP+vOzuYPNjTg9ZVfJ811kGaen7JwEszaL8gBSXoT23EzocgsggnZ9wAzFykUoaBWqwkpqVdJHucoLMlQih2GV+F/cmbBzDNT7dgAAAABJRU5ErkJggg=="));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Elf #',toString(id_),'", "description":"EthernalElves is a collection.", "image": "',
                                'data:image/svg+xml;base64,',
                                svg,
                                '",',
                                '"attributes": [{"trait_type": "level", "value": 12},{"display_type": "boost_number","trait_type": "zug bonus", "value":5}]',
                                '}'
                            )
                        )
                    )
                )
            );
    }
    

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function call(address source, bytes memory sig) internal view returns (string memory svg) {
        (bool succ, bytes memory ret)  = source.staticcall(sig);
        require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }


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

}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}