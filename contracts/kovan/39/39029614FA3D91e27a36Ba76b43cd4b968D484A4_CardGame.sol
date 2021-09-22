/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract CardGameS1{
    address internal dev;
    
    address internal candidateDev;
    
     //1.卡合成
     //2. 卡消耗消耗销毁
    struct Attribute{
        Sex identity;
        uint8 grades;
        uint256 regainTime;
        uint8 giveNumber;
        bool giveStatus;
    }
    bytes4 internal  _retval;
    Error internal  _error;
    
    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x5175f878;
    
    mapping (uint256 => Attribute) internal attribute;
    
    enum Sex{
        no,
        man,
        woman
    }
    
    enum GiveLimit{
        zero,
        one,
        two,
        limit
    }
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    external returns (bytes4);
}

interface IERC721  {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    function balanceOf(address owner) external  view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external  view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function transfer(address to, uint256 tokenId) external;
    function mint(address to,uint256 tokenId,string memory tokenURI)external;
    function burn(uint256 tokenId)external;
   function burnFrom(address from,uint256 tokenId)external;
}


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function  decimals() external view returns (uint8);
}

contract CardGame is IERC721Receiver, Context, CardGameS1  {
    using SafeMath for uint256;
    struct Counter {
        uint256 _value; // default: 0
    }
    event Received(address operator, address from, uint256 tokenId, bytes data );
    IERC721 erc721 = IERC721(0x24BAF0f53A29A23b452fbFEc7B7c42589A653596);
    IERC20  erc20 = IERC20(0x623427Bc5250c83DB910cB541BB422E986aDc5b1);
    event ReCombination(address to,uint256 tokenId,uint256 burnTokenId,uint8 grades );
    event Reproduction(address to,uint256 tokenId,uint256 tokenIdA,uint256 tokenIdB);
    struct NewCard{
        uint256 wasBornTime;
        Sex _sex;
        address to;
    }
    
    mapping(uint256=>mapping(uint256 => NewCard)) private _newCards;
    Counter private  counters;
    
    constructor() {
      counters._value=15;
      dev = address(0x1b5Fe099068C237Aaa3C291CeBB1b793e85243Fa);
    }
    
    // write
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        emit Received(operator, from, tokenId, data);
        return _INTERFACE_ID_ERC721;
    }
    
    // 新卡生成
    function mint(address to,uint256 tokenId,string memory tokenURI) public virtual{
      require(_msgSender()==dev,'CardGame : no permission');
      erc721.mint(to,tokenId,tokenURI);
      Sex  sex =  tokenId % 2 == 0 ? Sex.man : Sex.woman;
      attribute[tokenId] = Attribute(sex,1,0,0,false);
    }
    
    //初级版
    // 复合卡升级
    function reCombination(uint256 tokenIdA,uint256 tokenIdB)public virtual {
        erc721.burnFrom(_msgSender(),tokenIdA);
        erc721.burnFrom(_msgSender(),tokenIdB);
        increment(counters);
        mint(_msgSender(),current(counters),string(new bytes(current(counters))));
    }
     // 繁殖新生卡
     function reProduction(uint256 tokenIdA,uint256 tokenIdB) public virtual{
          require(erc721.ownerOf(tokenIdA) == _msgSender() && erc721.ownerOf(tokenIdB) == _msgSender(),"CardGame : Not the owner");
          increment(counters);
          mint(_msgSender(), current(counters),string(new bytes(current(counters))));
     }
     
    // 进阶版
    // 复合卡升级
    function reCombination(address to,uint256 tokenIdA,uint256 tokenIdB,Sex sex) public virtual {
        require(getAttribute(tokenIdA).grades == getAttribute(tokenIdA).grades,"CardGame : Compound failure levels are inconsistent");
        require(erc721.ownerOf(tokenIdA) == _msgSender(),"CardGame : Not the owner");
        // Transfer Judgment ID
        erc721.transferFrom(_msgSender(),address(this),tokenIdB);
        uint8  grade = getAttribute(tokenIdA).grades + 1 ;
        attribute[tokenIdA] = Attribute(sex,grade,block.timestamp + 10 minutes,getAttribute(tokenIdA).giveNumber,getAttribute(tokenIdA).giveStatus);
        delete attribute[tokenIdB] ;
        erc721.burn(tokenIdB);
        erc20.transferFrom(_msgSender(),address(this),grade*(10**uint256(erc20.decimals())));
        emit ReCombination(to,tokenIdA,tokenIdB,grade);
    }
    // 繁殖新生卡
    function reProduction(address to,uint256 tokenIdA,uint256 tokenIdB) public virtual{
        require(getAttribute(tokenIdA).identity != getAttribute(tokenIdA).identity,"CardGame : The same gender");
        require(erc721.ownerOf(tokenIdA) == _msgSender() && erc721.ownerOf(tokenIdB) == _msgSender(),"CardGame : Not the owner");
        require(getAttribute(tokenIdA).giveNumber >= 3 &&getAttribute(tokenIdA).giveNumber >= 3 ,"CardGame : exceed the limit ");
        (uint256 token0,uint256 token1) =tokenIdA > tokenIdB ?(tokenIdA,tokenIdB):(tokenIdB,tokenIdA);
        require(_newCards[token0][token1].wasBornTime>0,"CardGame : In the breeding");
        Sex  sex = block.timestamp % 2 == 0 ? Sex.man : Sex.woman;
        uint256 _wasBornTime = uint256(getAttribute(tokenIdA).giveNumber).mul(1 days).add(uint256(getAttribute(tokenIdB).giveNumber).mul(1 days));
        _newCards[token0][token1] = NewCard(_wasBornTime,sex,to);
        attribute[tokenIdA].giveStatus = true;
        attribute[tokenIdB].giveStatus = true;
        attribute[tokenIdA].giveNumber = attribute[tokenIdA].giveNumber+1;
        attribute[tokenIdB].giveNumber = attribute[tokenIdB].giveNumber+1;
    }
   
   function getNewCard(uint256 tokenIdA,uint256 tokenIdB)public virtual{
       (uint256 token0,uint256 token1) =tokenIdA > tokenIdB ?(tokenIdA,tokenIdB):(tokenIdB,tokenIdA);
       uint256 timestamp = block.timestamp;
       require(_newCards[token0][token1].wasBornTime<=timestamp,"CardGame : For the delivery of");
       increment(counters);
       NewCard memory card = _newCards[token0][token1];
       delete _newCards[token0][token1];
       mint(card.to,current(counters),string(new bytes(current(counters))));
       emit Reproduction(card.to,current(counters),tokenIdA,tokenIdB);

   }
    
    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }   
   //read
   function getAttribute(uint256 tokenId) public  view returns(Attribute memory info){
       info = attribute[tokenId];
   }
   function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
   }
  
}