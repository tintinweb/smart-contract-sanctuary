pragma solidity 0.6.12;

/**
Bird On-chain Oracle to confirm rating with 50% consensus before update using the off-chain API https://www.bird.money/docs
*/

// © 2020 Bird Money
// SPDX-License-Identifier: MIT

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BirdOracle {
    using SafeMath for uint256;

    BirdRequest[] public onChainRequests; //keep track of list of on-chain

    address public owner;

    uint256 public minConsensusPercentage = 50; //minimum percentage of consensus before confirmation
    uint256 public birdNest = 0; // birds in nest count // total trusted providers
    uint256 public trackId = 0;

    address[] public providers; //offchain oracle nodes
    mapping(address => uint256) statusOf; //offchain data provider address => TRUSTED or NOT

    //status of providers with respect to all requests
    uint8 constant NOT_TRUSTED = 0;
    uint8 constant TRUSTED = 1;
    uint8 constant WAS_TRUSTED = 2;

    //status of with respect to individual request
    uint8 constant NOT_VOTED = 0;
    uint8 constant VOTED = 2;

    /**
     * Bird Standard API Request
     * id: "1"
     * ethAddress: address(0xcF01971DB0CAB2CBeE4A8C21BB7638aC1FA1c38c)
     * key: "bird_rating"
     * value: 400000000000000000   // 4.0
     * resolved: true / false
     * votesOf: 000000010000=> 2  (specific answer => number of votes of that answer)
     * statusOf: 0xcf021.. => VOTED
     */

    struct BirdRequest {
        uint256 id;
        address ethAddress;
        string key;
        uint256 value;
        bool resolved;
        mapping(uint256 => uint256) votesOf; //specific answer => number of votes of that answer
        mapping(address => uint256) statusOf; //offchain data provider address => VOTED or NOT
    }

    mapping(address => uint256) private ratingOf; //saved ratings of eth addresses after consensus

    /**
     * Bird Standard API Request
     * Off-Chain-Request from outside the blockchain
     */
    event OffChainRequest(uint256 id, address ethAddress, string key);

    /**
     * To call when there is consensus on final result
     */
    event UpdatedRequest(
        uint256 id,
        address ethAddress,
        string key,
        uint256 value
    );

    event ProviderAdded(address provider);
    event ProviderRemoved(address provider);

    modifier onlyOwner {
        require(msg.sender == owner, "Owner can call this function");
        _;
    }

    modifier paymentApproved(address _ethAddressToQuery) {
        require(
            msg.sender == _ethAddressToQuery || isApproved(msg.sender),
            "Please pay BIRD to BirdOracle"
        );
        _;
    }

    constructor(address _birdTokenAddr) public {
        owner = msg.sender;
        birdToken = IERC20(_birdTokenAddr);
    }

    function addProvider(address _provider) public onlyOwner {
        require(statusOf[_provider] != TRUSTED, "Provider is already added.");

        if (statusOf[_provider] == NOT_TRUSTED) providers.push(_provider);
        statusOf[_provider] = TRUSTED;
        ++birdNest;

        emit ProviderAdded(_provider);
    }

    function removeProvider(address _provider) public onlyOwner {
        require(statusOf[_provider] == TRUSTED, "Provider is already removed.");

        statusOf[_provider] = WAS_TRUSTED;
        --birdNest;

        emit ProviderRemoved(_provider);
    }

    function newChainRequest(address _ethAddress, string memory _key)
        public
        paymentApproved(_ethAddress)
    {
        onChainRequests.push(
            BirdRequest({
                id: trackId,
                ethAddress: _ethAddress,
                key: _key,
                value: 0, // if resolved is true then read value
                resolved: false // if resolved is false then value do not matter
            })
        );

        /**
         * Off-Chain event trigger
         */
        emit OffChainRequest(trackId, _ethAddress, _key);

        /**
         * update total number of requests
         */
        trackId++;
    }

    /**
     * called by the Off-Chain oracle to record its answer
     */
    function updatedChainRequest(uint256 _id, uint256 _response) public {
        BirdRequest storage req = onChainRequests[_id];

        require(
            req.resolved == false,
            "Error: Consensus is complete so you can not vote."
        );
        require(
            statusOf[msg.sender] == TRUSTED,
            "Error: You are not allowed to vote."
        );

        require(
            req.statusOf[msg.sender] == NOT_VOTED,
            "Error: You have already voted."
        );

        req.statusOf[msg.sender] = VOTED;
        uint256 thisAnswerVotes = ++req.votesOf[_response];

        if (thisAnswerVotes >= _minConsensus()) {
            req.resolved = true;
            req.value = _response;
            ratingOf[req.ethAddress] = _response;
            emit UpdatedRequest(req.id, req.ethAddress, req.key, req.value);
        }
    }

    function _minConsensus() private view returns (uint256) {
        uint256 minConsensus = birdNest.mul(minConsensusPercentage).div(100);
        return minConsensus;
    }

    function getRatingByAddress(address _ethAddress)
        public
        view
        paymentApproved(_ethAddress)
        returns (uint256)
    {
        return ratingOf[_ethAddress];
    }

    function getRating() public view returns (uint256) {
        return ratingOf[msg.sender];
    }

    //get trusted providers
    function getProviders() public view returns (address[] memory) {
        address[] memory trustedProviders = new address[](birdNest);
        uint256 t_i = 0;
        for (uint256 i = 0; i < providers.length; i++) {
            if (statusOf[providers[i]] == TRUSTED) {
                trustedProviders[t_i] = providers[i];
                t_i++;
            }
        }
        return trustedProviders;
    }

    IERC20 public birdToken;

    uint256 public priceToAccessOracle = 1 * 1e18; //rate of 30 days to access data is 1 BIRD
    mapping(address => uint256) public dueDateOf; // who paid the money at whatis his due date. //handle case a person called

    function sendPayment() public {
        address buyer = msg.sender;
        birdToken.transferFrom(buyer, address(this), priceToAccessOracle); // charge money from sender if he wants to access our oracle

        uint256 dueDate = dueDateOf[buyer];
        uint256 next30Days = now + 30 days;

        if (dueDate > now && dueDate < next30Days) {
            dueDateOf[buyer] = dueDate + next30Days;
        } else {
            dueDateOf[buyer] = now + next30Days;
        }
    }

    uint256 lastTimeRewarded = 0;

    function rewardProviders() public {
        //rewardProviders can be called once in a day
        uint256 timeAfterRewarded = now - lastTimeRewarded;
        require(
            timeAfterRewarded > 24 hours,
            "You can call reward providers once in 24 hrs"
        );

        //give 50% BIRD in this contract to owner and 50% to providers
        uint256 rewardToOwnerPercentage = 50; // 50% reward to owner and rest money to providers

        uint256 balance = birdToken.balanceOf(address(this));
        uint256 rewardToOwner = balance.mul(rewardToOwnerPercentage).div(100);
        uint256 rewardToProviders = balance - rewardToOwner;
        uint256 rewardToEachProvider = rewardToProviders.div(birdNest);

        birdToken.transfer(owner, rewardToOwner);

        for (uint256 i = 0; i < providers.length; i++) {
            if (statusOf[providers[i]] == TRUSTED) {
                birdToken.transfer(providers[i], rewardToEachProvider);
            }
        }
        lastTimeRewarded = now;
    }

    function isApproved(address _addr) public view returns (bool) {
        return now < dueDateOf[_addr];
    }
}