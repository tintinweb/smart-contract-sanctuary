/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;


contract ChannelAuction {

    enum Status {
            REGISTER,
            PENDING,
            GR, // Bid increased via GR = English-Auction
            LOTTERY,
            DONE
        }
        
    Status public status = Status.REGISTER;

    struct Member {
        uint balance;
        bytes32 commit;
    }
	mapping(address => Member) _members; //Bidder Management // Bidder == Member
    address[] public memNm; //Lottery Number for Bidder 

    address payable seller; 
    address payable owner; 
    address buyer;

    uint256 incAccepTime = 100; //Time to register for auction & Lottery 
    uint256 accepTimer = block.timestamp + incAccepTime;
    uint256 public bidN; //Counter for GR-Bidder-Pool // GR = English-Auction

    uint256 public Rnew; // Random Number for the lottery
    uint256 public Rold;

    uint256 public priceNL; // Price of NL  == instant buy // NL = Dutch-Auction
    uint256 public priceGR; // Price of GR == bid 
    uint256 public minStep; // minimal price increase for a bid 
    uint256 public oldPriceGR; // for increase deposit with the function acceptIncressedBid() 
    uint256 public priceChannel; // Price for closing the channel of the auction
    uint256  priceDiff;

    event aktPriceNL (uint256 priceNL);
    event aktStatus (Status status);
    event commitIO();
    event keccakReveal(bytes32 reveal);
    event revealIO();
    event delMember(address exMember);
    event ranNEW(uint256 nm);

    modifier onlyMember(address member_, bool registered) {
        require(msg.sender != seller, 'you are the seller');
        if(registered) {
            require(_members[member_].balance >= oldPriceGR, 'must be registered');
        } else {
            require(_members[member_].balance == 0, 'must NOT be registered');
        }
        _;
    }

    function initialize(uint256 _incAccepTime, uint256 _priceMax, uint256 _minStep, address payable _seller) external {
        require(seller == address(0), 'init is over');
        //update the time settings
        incAccepTime = _incAccepTime;
        accepTimer = block.timestamp + _incAccepTime;
        //Update the price settings
        priceNL = _priceMax - _minStep;
        priceChannel = _priceMax / 2;
        minStep = _minStep;
        priceGR = _minStep;
        oldPriceGR = _minStep;
        seller = _seller;
    }

    function register(bytes32 newCommit) external payable onlyMember(msg.sender, false){
        if (block.timestamp > accepTimer && status == Status.REGISTER){
            status = Status.PENDING;
            }
        require(status == Status.REGISTER, "Registration is closed");
        require(msg.value == priceGR, 'deposit do not match');
        require(newCommit != 0, 'can not be empty');
        _members[msg.sender] = Member(
            msg.value,
            newCommit//keccak256(abi.encodePacked("13", "13"))
            );
        bidN ++;
        emit aktPriceNL(priceNL);
    }

    function exitNoRegistation() external {
        require(msg.sender == seller, "you are not the seller");
        require(status == Status.REGISTER, "not in REGISTER mod");
        require(bidN == 0, "registration is not empty");
        kill();
    }

    function bid() external payable onlyMember(msg.sender, true){
        if (block.timestamp >= accepTimer){
            if( status == Status.REGISTER){
                status = Status.PENDING; 
            }
            else if (status == Status.GR && bidN > 0){
                status = Status.PENDING;
                oldPriceGR = priceGR;
            }
        }
        require(status == Status.PENDING, "not in PENDING mod");
        require(msg.value >= minStep, 'deposit do not match');
        uint256 valBid = msg.value + (_members[msg.sender].balance);
        /// @notice check Winner via NL
        if (valBid >= priceNL){
            status = Status.DONE;
            oldPriceGR = 0;
            }
        /// @notice check if Channel closed via NL == GR
        else if (status != Status.DONE && valBid >= priceChannel){ //safe mathe evt einmal bereichene channelPrice
            //require(valBid > priceChannel, 'overChannel');
            status = Status.LOTTERY;
            
            }
        /// @notice increase Channel with msg.value
        else {
            status = Status.GR;
            oldPriceGR = priceGR;
            }
        buyer = msg.sender;
        priceGR += msg.value;
        priceNL -= msg.value;
        priceDiff = priceGR - oldPriceGR;
        emit aktPriceNL(priceNL);
        accepTimer = block.timestamp + incAccepTime;
        _members[msg.sender].balance += msg.value;
        bidN = 0;
    }

    function acceptIncressedBid()
        external
        payable
        onlyMember(msg.sender, true)
        {
        if ((block.timestamp > accepTimer) && (bidN == 0)){
            status = Status.DONE;
            oldPriceGR = 0;
            return; 
            }
        require(status == Status.GR, "not in GR mod");
        
        require( msg.value == priceDiff , "deposit do not match"); 
        _members[msg.sender].balance += msg.value;
        bidN ++;
    }

    function enterLottery (uint256 ranNm, string memory salt)
        external
        payable
        onlyMember(msg.sender, true) 
        {
        if (block.timestamp >= accepTimer){
            status = Status.DONE;
            oldPriceGR = 0;
            return; 
            }
        require(status == Status.LOTTERY, "Auction is not in RELOTTERY");
        require(msg.value == priceDiff, "deposit do not match");
        revealRan(ranNm, salt);
    }


    function transfer() external{
        require(status == Status.DONE, "Auction is not over");
        require(msg.sender == seller || msg.sender == buyer, "You are not buyer or seller");
        uint256 amount = _members[buyer].balance;
        delete _members[buyer];
        (bool success, ) = seller.call{value: amount}("");
        require(success, "Transfer failed.");
        
    }

    function withdraw () external onlyMember(msg.sender, true){
        require(status == Status.DONE, "Auction is not over");
        require(msg.sender != buyer, "You are the buyer");
        uint256 amount = _members[msg.sender].balance;
        delete _members[msg.sender];
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    //*********************************************************************** */

    function getDeposit() external view onlyMember(msg.sender, true) returns(uint256){
        return _members[msg.sender].balance;
    }

    function getBuyer() external view onlyMember(msg.sender, true) returns(address){
        return buyer;
    }

    

    //*********************************************************************** */
    function kill() private{
        selfdestruct(seller);
    }

    function revealRan (uint256 ranNm, string memory salt) private{
        bytes32 tocommit = keccak256(abi.encodePacked(ranNm, salt));
        emit keccakReveal(tocommit);
        bytes32 commited = _members[msg.sender].commit;
        if (tocommit != commited){
            delete _members[msg.sender];
            emit delMember(msg.sender);
            revert("wrong reveal");
        }
        if (tocommit == commited){
            memNm.push(msg.sender);
            bidN++;
            emit revealIO();
            if (Rnew == 0){
            Rnew = block.timestamp%251; 
            }
            Rold = Rnew;
            Rnew = Rnew^ranNm;
            buyer = memNm[Rnew%memNm.length];
        }
    }
}