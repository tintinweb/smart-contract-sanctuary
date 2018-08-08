pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t h4old
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint32 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        assert(b <= a);
        return a - b;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint16 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _from, address _to, uint256 _tokenId) internal;
    function takeOwnership(uint256 _tokenId) public;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event TransferOwnership(address oldaddr, address newaddr);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address _new) public onlyOwner {
        address oldaddr = owner;
        owner = _new;
        emit TransferOwnership(oldaddr, owner);
    }
}

contract GameCoin is Ownable {

    using SafeMath for uint256;

    event NewCmas(uint cmasId, string name);

    struct Cmas {
        string name;
        uint cmasId;
        uint32 birthTime;
        uint cmasPrice;
    }

    uint randNonece = 0;

    Cmas[] public cmases;

    mapping (uint => address) public cmasToOwner;
    mapping (address => uint) ownerCmasCount;

    modifier onlyOwnerOf(uint _cmasId) {
        require(msg.sender == cmasToOwner[_cmasId]);
        _;
    }

    function newCmas(uint _supply, string _name) public onlyOwner {
        for(uint i = 0; i < cmases.length; i++) {
            require(keccak256(abi.encodePacked(cmases[i].name)) != keccak256(abi.encodePacked(_name)));
        }
        uint id = cmases.push(Cmas(_name, uint(keccak256(abi.encodePacked(now, msg.sender, randNonece))), uint32(now), _supply * 1 ether)) -1;
        cmasToOwner[id] = msg.sender;
        ownerCmasCount[msg.sender] = ownerCmasCount[msg.sender].add(1);
        emit NewCmas(id, _name);
    }
    
    function getCmasByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](ownerCmasCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < cmases.length; i++) {
      if (cmasToOwner[i] == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

}

contract CmasOwnerShip is GameCoin, ERC721 {

    mapping (uint => address) cmasApprovals;
    
    function totalSupply() public view returns (uint) {
        return cmases.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerCmasCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        return cmasToOwner[_tokenId];
    }

    function transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_from == cmasToOwner[_tokenId]);
        ownerCmasCount[_to]++;
        ownerCmasCount[_from]--;
        cmasToOwner[_tokenId] = _to;
        cmases[_tokenId].cmasPrice = cmases[_tokenId].cmasPrice + cmases[_tokenId].cmasPrice * 20 / 100;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) external onlyOwnerOf(_tokenId) {
        cmasApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(cmasApprovals[_tokenId] == msg.sender);
        address owner = ownerOf(_tokenId);
        transfer(owner, msg.sender, _tokenId);
    }
}

contract Escrow is CmasOwnerShip {
    
    // 최상위 컨트렉트
    // 판매 정보 구조체
    struct EscrowInfo {
        address seller;
        uint tokenId;
        uint sellingPrice;
        bool isOpened;
    }
    
    mapping (uint => EscrowInfo) public tokenIdToEscrow;
    mapping (uint => bool) internal tokenOpenAuction;
    
    event EscrowStart(uint tokenId, uint sellingPrice, address beneficiary);
    event ConfirmedPayment(address addr, uint amount);
    event Transfer(address indexed from, address indexed to, uint value);
    
    modifier onlySeller(uint _tokenId) {
        require(tokenIdToEscrow[_tokenId].seller == msg.sender);
        _;
    }
    
    /* mapping에 판매정보를 저장 */
    function newEscrow(uint _tokenId) public onlyOwnerOf(_tokenId) {
        require(tokenIdToEscrow[_tokenId].isOpened == false);
        require(tokenOpenAuction[_tokenId] == false);
        Cmas memory myCmas = cmases[_tokenId];
        tokenIdToEscrow[_tokenId] =  EscrowInfo(msg.sender, _tokenId, myCmas.cmasPrice, false);
        
        start(_tokenId);
    }
    
    // 판매 시작
    function start(uint _tokenId) private onlySeller(_tokenId) {
        require(tokenIdToEscrow[_tokenId].seller == msg.sender);
        require(tokenIdToEscrow[_tokenId].sellingPrice != 0);
           tokenIdToEscrow[_tokenId].isOpened = true;
           emit EscrowStart(tokenIdToEscrow[_tokenId].tokenId, 
           tokenIdToEscrow[_tokenId].sellingPrice, owner);
    }
    
     // 금액 전송 함수
    function withdraw(uint _tokenId) public payable {
        require(tokenIdToEscrow[_tokenId].isOpened);
        require(msg.sender != tokenIdToEscrow[_tokenId].seller);
        
        uint amount = msg.value;
        require(amount >= tokenIdToEscrow[_tokenId].sellingPrice);
        
        tokenIdToEscrow[_tokenId].seller.transfer(msg.value - (msg.value / 1000));
        owner.transfer(msg.value / 1000);
        transfer(cmasToOwner[_tokenId], msg.sender, tokenIdToEscrow[_tokenId].tokenId);
        tokenIdToEscrow[_tokenId].isOpened = false;
        emit ConfirmedPayment(msg.sender, tokenIdToEscrow[_tokenId].tokenId);
    }
    
    // 판매종료
    function close(uint _tokenId) public onlySeller(_tokenId) {
        require(tokenIdToEscrow[_tokenId].isOpened == true);
        tokenIdToEscrow[_tokenId].isOpened = false;
    }
    
    function escrowList() external view returns (uint[]) {
        uint length = 0;
        for (uint i = 0; i < cmases.length; i++) {
            if (tokenIdToEscrow[i].isOpened == true) {
            length++;
            }
        }
        require(length > 0);
        uint[] memory result = new uint[](length);
        uint counter = 0;
        for (uint j = 0; j < cmases.length; j++) {
            if (tokenIdToEscrow[j].isOpened == true) {
            result[counter] = j;
            counter++;
            }
        }
        return result;
    }
    
}

contract SimpleAuction is Escrow {
    
    struct Auction {
        address seller; // 판매자
        uint startingPrice; //최소 시작 금액
        uint deadline; // 기간 분 단위
        uint startedAt; // 시작 시간
        address highestBidder; // 돈 많이 낸 사람
        uint highestBid; // 돈 많이 낸 금액
        bool isOpened; // 경매 진행 중 인가
    }
    
    mapping (uint => Auction) public tokenIdToAuction; // 경매 목록이 담긴 mapping
     // Allowed withdrawals of previous bids 이전 입찰가의 인출 허용
    mapping(address => uint) pendingReturns;
    
    event AuctionCreated(uint tokenId, uint startingPriceuint, uint deadline);
    event AuctionSuccessful(uint tokenId, uint totalPrice, address winner);
    event AuctionCancelled(uint tokenId);
    event HighestBidIncreased(address bidder, uint amount);
    
    modifier onlyAuctionSeller(uint _tokenId) {
        require(tokenIdToAuction[_tokenId].seller == msg.sender);
        _;
    }
    
    // 경매 만들기
    function newAuction(uint _tokenId, uint _deadline) public onlyOwnerOf(_tokenId) {
        require(tokenIdToEscrow[_tokenId].isOpened == false);
        require(tokenIdToAuction[_tokenId].isOpened == false);
        tokenIdToAuction[_tokenId] = 
        Auction(msg.sender, cmases[_tokenId].cmasPrice, now + _deadline * 1 minutes, now, 0, 0, true);
        tokenOpenAuction[_tokenId] = true;
        
        emit AuctionCreated(_tokenId, now, _deadline);
    }
    
    // 경매 참여
    function bid(uint _tokenId) public payable {
        // No arguments are necessary, all
        // information is already part of
        // the transaction. The keyword payable
        // is required for the function to
        // be able to receive Ether.
        // Revert the call if the bidding
        // period is over.
        
        require(msg.sender != tokenIdToAuction[_tokenId].seller);
        require(now <= tokenIdToAuction[_tokenId].deadline);
        require(tokenIdToAuction[_tokenId].isOpened);
        require(tokenIdToAuction[_tokenId].highestBidder != msg.sender);

        // If the bid is not higher, send the
        // money back.
        require(msg.value >= tokenIdToAuction[_tokenId].startingPrice);
        require(msg.value > tokenIdToAuction[_tokenId].highestBid);

        if (tokenIdToAuction[_tokenId].highestBid != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingReturns[tokenIdToAuction[_tokenId].highestBidder] += tokenIdToAuction[_tokenId].highestBid;
        }
        
        tokenIdToAuction[_tokenId].highestBidder = msg.sender;
        tokenIdToAuction[_tokenId].highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }
    
    // 경매 돈 돌려 받기
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;
            
            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    // 경매 종료
    function auctionEnd(uint _tokenId) public onlyAuctionSeller(_tokenId) {
        // 1. Conditions
        require(now >= tokenIdToAuction[_tokenId].deadline); // auction did not yet end
        require(tokenIdToAuction[_tokenId].isOpened); // this function has already been called

        // 2. Effects
        tokenIdToAuction[_tokenId].isOpened = false;
        emit AuctionCancelled(_tokenId);

        // 3. Interaction
        tokenIdToAuction[_tokenId].seller.transfer(tokenIdToAuction[_tokenId].highestBid);
        transfer(tokenIdToAuction[_tokenId].seller, tokenIdToAuction[_tokenId].highestBidder, _tokenId);
    }
    
    function auctionList() external view returns (uint[]) {
        uint length = 0;
        for (uint i = 0; i < cmases.length; i++) {
            if (tokenIdToAuction[i].isOpened == true) {
            length++;
            }
        }
        require(length > 0);
        uint[] memory result = new uint[](length);
        uint counter = 0;
        for (uint j = 0; j < cmases.length; j++) {
            if (tokenIdToAuction[j].isOpened == true) {
            result[counter] = j;
            counter++;
            }
        }
        return result;
    }
}