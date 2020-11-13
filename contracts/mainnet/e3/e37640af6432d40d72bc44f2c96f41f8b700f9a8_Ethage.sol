// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract Ethage {

    struct User {
        uint128 mtx3Block;
        uint128 mtx6Block;
        address parent;
    }

    uint128 public constant NO_OF_BLOCKS = 12;

    mapping(address => User) public users;

    mapping(uint256 => uint256) public blockPriceMtx3;
    mapping(uint256 => uint256) public blockPriceMtx6;

    address owner;
    address ai;
    uint public aiGasCode = 0.009 ether;

    event Registration(address indexed user, address indexed referrer);
    event Upgrade(address indexed user, uint256 matrix, uint256 blockLevel);

    constructor(address ownerAddress, address a, address b, address c, address d, address e) public {

        blockPriceMtx3[1] = 0.03 ether;
        blockPriceMtx3[2] = 0.06 ether;
        blockPriceMtx3[3] = 0.12 ether;
        blockPriceMtx3[4] = 0.24 ether;
        blockPriceMtx3[5] = 0.5 ether;
        blockPriceMtx3[6] = 1.0 ether;
        blockPriceMtx3[7] = 2.0 ether;
        blockPriceMtx3[8] = 4.0 ether;
        blockPriceMtx3[9] = 8.0 ether;
        blockPriceMtx3[10] = 16.0 ether;
        blockPriceMtx3[11] = 32.0 ether;
        blockPriceMtx3[12] = 64.0 ether;

        blockPriceMtx6[1] = 0.02 ether;
        blockPriceMtx6[2] = 0.06 ether;
        blockPriceMtx6[3] = 0.12 ether;
        blockPriceMtx6[4] = 0.24 ether;
        blockPriceMtx6[5] = 0.5 ether;
        blockPriceMtx6[6] = 1.0 ether;
        blockPriceMtx6[7] = 2.0 ether;
        blockPriceMtx6[8] = 4.0 ether;
        blockPriceMtx6[9] = 8.0 ether;
        blockPriceMtx6[10] = 16.0 ether;
        blockPriceMtx6[11] = 32.0 ether;
        blockPriceMtx6[12] = 64.0 ether;


        ai = msg.sender;
        owner = ownerAddress;

        User memory user = User({
            mtx3Block : NO_OF_BLOCKS,
            mtx6Block : NO_OF_BLOCKS,
            parent : address(0)
            });

        users[ownerAddress] = user;

        init(a, b, c, d, e);
    }

    function safeAdd(uint a, uint b) private pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    modifier onlyAiRelay {
        require(
            msg.sender == ai,
            "Only Ai Relay can call this function."
        );
        _;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].mtx3Block != 0);
    }

    function init(address a, address b, address c, address d, address e) private {
        User memory userA = User({
            mtx3Block : NO_OF_BLOCKS,
            mtx6Block : NO_OF_BLOCKS,
            parent : owner
            });

        users[a] = userA;

        User memory userB = User({
            mtx3Block : NO_OF_BLOCKS,
            mtx6Block : NO_OF_BLOCKS,
            parent : owner
            });

        users[b] = userB;

        User memory userC = User({
            mtx3Block : NO_OF_BLOCKS,
            mtx6Block : NO_OF_BLOCKS,
            parent : a
            });

        users[c] = userC;

        User memory userD = User({
            mtx3Block : NO_OF_BLOCKS,
            mtx6Block : NO_OF_BLOCKS,
            parent : a
            });

        users[d] = userD;

        User memory userE = User({
            mtx3Block : NO_OF_BLOCKS,
            mtx6Block : NO_OF_BLOCKS,
            parent : b
            });

        users[e] = userE;
    }

    function nextAvailableBlockMtx3(uint256 blockLevel) public view returns (bool){
        uint256 nextAvailable = users[msg.sender].mtx3Block + 1;
        return (nextAvailable == blockLevel);
    }

    function nextAvailableBlockMtx6(uint256 blockLevel) public view returns (bool){
        uint256 nextAvailable = users[msg.sender].mtx6Block + 1;
        return (nextAvailable == blockLevel);
    }


    function signUp(address referrerAddress) external payable {
        require(msg.value == safeAdd(0.05 ether, aiGasCode), "sign up cost 0.05 + AI Price");
        require(isUserExists(referrerAddress), "referrer not exists");
        require(!isUserExists(msg.sender), "user exists");

        User memory user = User({
            mtx3Block : 1,
            mtx6Block : 1,
            parent : referrerAddress
            });

        users[msg.sender] = user;
        emit Registration(msg.sender, referrerAddress);

        if (!address(uint160(ai)).send(aiGasCode)) {
            address(uint160(ai)).transfer(aiGasCode);
        }

    }

    function purchaseMtx3(uint256 blockLevel) external payable {
        require(isUserExists(msg.sender), "user is not exists. Sign Up first.");
        require(msg.value == safeAdd(blockPriceMtx3[blockLevel], aiGasCode), "invalid price");
        require(blockLevel > 1 && blockLevel <= NO_OF_BLOCKS, 'invalid block');
        require(nextAvailableBlockMtx3(blockLevel), "invalid block");

        users[msg.sender].mtx3Block++;
        emit Upgrade(msg.sender, 1, blockLevel);

        if (!address(uint160(ai)).send(aiGasCode)) {
            address(uint160(ai)).transfer(aiGasCode);
        }
    }

    function purchaseMtx6(uint256 blockLevel) external payable {
        require(isUserExists(msg.sender), "user is not exists. Sign Up first.");
        uint requiredPrice = safeAdd(blockPriceMtx6[blockLevel], aiGasCode);
        require(msg.value == requiredPrice, "invalid price");
        require(blockLevel > 1 && blockLevel <= NO_OF_BLOCKS, 'invalid block');
        require(nextAvailableBlockMtx6(blockLevel), "invalid block");

        users[msg.sender].mtx6Block++;
        emit Upgrade(msg.sender, 2, blockLevel);

        if (!address(uint160(ai)).send(aiGasCode)) {
            address(uint160(ai)).transfer(aiGasCode);
        }

    }

    function signUpDividend(address mtx3Receiver, address mtx6Receiver, uint8 nonce) public onlyAiRelay {
        require(isUserExists(mtx3Receiver), "mtx3Receiver does not exist.");
        require(isUserExists(mtx6Receiver), "mtx6Receiver does not exist.");
        require(nonce > 0, "invalid nonce");
        if (!address(uint160(mtx3Receiver)).send(blockPriceMtx3[1])) {
            address(uint160(mtx3Receiver)).transfer(blockPriceMtx3[1]);
        }

        if (!address(uint160(mtx6Receiver)).send(blockPriceMtx6[1])) {
            address(uint160(mtx6Receiver)).transfer(blockPriceMtx6[1]);
        }
    }


    function dividend(address receiver, uint matrix, uint blockLevel, uint8 nonce) public onlyAiRelay {
        require(isUserExists(receiver), "receiver does not exist.");
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(nonce > 0, "invalid nonce");
        if (matrix == 1) {
            sendDividendMtx3(receiver, blockLevel);
        } else {
            sendDividendMtx6(receiver, blockLevel);
        }

    }

    function usersActiveX3Block(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].mtx3Block >= level;
    }

    function usersActiveX6Block(address userAddress, uint8 level) public view returns (bool) {
        return users[userAddress].mtx6Block >= level;
    }

    function getUser(address userAddress) public view returns (uint128, uint128, address) {
        return (users[userAddress].mtx3Block,
        users[userAddress].mtx6Block,
        users[userAddress].parent);
    }

    function sendDividendMtx3(address receiver, uint blockLevel) private {
        if (!address(uint160(receiver)).send(blockPriceMtx3[blockLevel])) {
            address(uint160(receiver)).transfer(blockPriceMtx3[blockLevel]);
        }
    }

    function sendDividendMtx6(address receiver, uint blockLevel) private {
        if (!address(uint160(receiver)).send(blockPriceMtx6[blockLevel])) {
            address(uint160(receiver)).transfer(blockPriceMtx6[blockLevel]);
        }
    }

    function updateAiGasCode(uint gas) public onlyAiRelay {
        aiGasCode = gas;
    }

    function updateAiAggregator(address aiProvider) public onlyAiRelay {
        ai = aiProvider;
    }
}