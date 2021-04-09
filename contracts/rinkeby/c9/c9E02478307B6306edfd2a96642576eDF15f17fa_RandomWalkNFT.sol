// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./NumericalMath.sol";
import "./FixidityLib.sol";
import "./VRFConsumerBase.sol";
import "./ERC721.sol";

/**
 * @title RandomWalkNFT
 * @author John Michael Statheros (GitHub: jstat17)
 * @notice Contract for creating random walk map NFTs.
 */
contract RandomWalkNFT is ERC721, VRFConsumerBase {
    
    bytes32 internal keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    address internal vrfCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B;
    address internal linkToken = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    uint256 internal fee;
    int256 public randomResult;
    
    struct RandomWalk {
        string name;
        uint256 ID;
        uint256 nodes;
        int256[] x;
        int256[] y;
    }
    
    RandomWalk[] private randomWalks;
    
    mapping(bytes32 => string) public requestToMapName;
    mapping(bytes32 => address) public requestToSender;
    mapping(bytes32 => uint256) public requestToTokenID;
    mapping(bytes32 => uint256) public requestToNodes;
    mapping(address => bytes32) public senderToRequest;
    
    struct Walker {
        int256 x;
        int256 y;
        int256 currAngle;
        int256 angle_orig;
        uint8 digits;
    }
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     * 
     * Network: Rinkeby
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * LINK token address:                0x01be23585060835e02b77ef475b0cc51aa1e0709
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311

     */
    constructor ()
    //constructor (address _VRFCoordinator, address _LinkToken, bytes32 _keyHash)
    ERC721("Random Walk","RWalk")
    VRFConsumerBase(vrfCoordinator, linkToken)
    //VRFConsumerBase(_VRFCoordinator, _LinkToken)
    public {
        //vrfCoordinator = _VRFCoordinator;
        //keyHash = _keyHash;
        fee = 0.1 * 10**18; // 0.1 LINK
    }
    
    /**
     * @notice This function must be called AFTER calling
     * the requestRandomWalk function.This will then
     * generate the random walk as an NFT and the sender
     * will have it added to their wallet and show up
     * in etherscan as an ERC721.
     * @return success -> true if successful
     */
    function generateRandomWalkNFT() public returns(bool success) {
        bytes32 requestID = senderToRequest[msg.sender];
        require(requestID != 0x0000000000000000000000000000000000000000000000000000000000000000);
        uint256 newID = randomWalks.length;
        requestToTokenID[requestID] = newID;
        
        int256[] memory xs = new int256[](requestToNodes[requestID]);
        int256[] memory ys = new int256[](requestToNodes[requestID]);
        xs[0] = 0;
        ys[0] = 0;
        
        // Constants:
        int256 _2pi = FixidityLib.multiply(FixidityLib.newFixed(2), NumericalMath.pi());
        int256 _pi_on_2 = FixidityLib.multiply(FixidityLib.divide(1, 2), NumericalMath.pi());
        int256 _pi_on_4 = FixidityLib.multiply(FixidityLib.divide(1, 4), NumericalMath.pi());
        
        // Struct to store walker details:
        Walker memory walker;
        walker.x = 0;
        walker.y = 0;
        
        // Starting angle between 0 and 2π rad:
        walker.angle_orig = NumericalMath.convBtwUpLo(randomResult, 0, _2pi);

        walker.digits = FixidityLib.digits();
        
        // Create all nodes of the walk:
        for (uint256 _i = 1; _i < requestToNodes[requestID]; _i++) {
            // Get new angle to walk towards
            if (_i == 1) {
                walker.currAngle = walker.angle_orig;
            } else {
                randomResult = NumericalMath.callKeccak256(abi.encodePacked(randomResult));
                walker.currAngle = FixidityLib.add(walker.currAngle, FixidityLib.subtract(NumericalMath.getRandomNum(randomResult, 0, _pi_on_2), _pi_on_4));
            }
            // Walk forwards in the new angle by 1 unit
            walker.x = FixidityLib.add(walker.x, NumericalMath.cos(walker.currAngle, walker.digits));
            walker.y = FixidityLib.add(walker.y, NumericalMath.sin(walker.currAngle, walker.digits));
            // Add new location as a node
            xs[_i] = walker.x;
            ys[_i] = walker.y;
            
        }
        // Add new Random Walk:
        randomWalks.push(
            RandomWalk(
                requestToMapName[requestID],
                newID,
                requestToNodes[requestID],
                xs,
                ys
            )
        );
        _safeMint(requestToSender[requestID], newID);
        senderToRequest[msg.sender] = 0x0000000000000000000000000000000000000000000000000000000000000000;
        return true;
    }
    
    /** The user enters an integer seed and the number
     * of walk nodes, then a random number is
     * generated by the VRF oracle and reserved
     * for the specific user that interacted with this
     * function.
     * @param userProvidedSeed: the integer seed
     * @param nodes: the number of nodes in the walk
     * @return requestID: the ID of the specific
     * request generated
     */
    function requestRandomWalk(uint256 userProvidedSeed, uint256 nodes) public returns(bytes32) {
        bytes32 requestID = requestRandomness(keyHash, fee, userProvidedSeed); // get a random number from the oracle
        requestToMapName[requestID] = string(abi.encodePacked(uint2str(nodes), "-node walk"));
        requestToSender[requestID] = msg.sender;
        requestToNodes[requestID] = nodes;
        //senderToRequest[msg.sender] = requestID;
        return requestID;
    }
    
    /**
     * @notice This is the function that the VRF
     * oracle interacts with.
     * @param requestID: the ID of the request of
     * the user done in requestRandomWalk function
     * @param randomness: the VRF oracle's generated
     * random number
     */
    function fulfillRandomness(bytes32 requestID, uint256 randomness) internal override {
        randomResult = FixidityLib.abs(int256(randomness));
        senderToRequest[requestToSender[requestID]] = requestID;
    }
    
    /**
     * @notice Set the token URI for an NFT so that it can be viewed
     * in a market like opensea.
     * @param tokenID: the ID of the specific NFT
     * @param _tokenURI: the token URI
     */
    function setTokenURI(uint256 tokenID, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenID),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenID, _tokenURI);
    }
    
    /**
     * @notice Input the unique token ID for an NFT
     * and all the details of it will be returned.
     * @param tokenID: the ID of the desired NFT
     * @return details of the NFT
     */
    function seeRandomWalk(uint256 tokenID) public view returns(RandomWalk memory) {
        return randomWalks[tokenID];
    }
    
    /**
     * @notice Function that converts a uint256 to a string.
     * Works for ^0.8.0 and below.
     * @param _i: uint256
     * @return _uintAsString
     * @dev created by Barnabas Ujvari (stackoverflow)
     * https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
     */
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
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
    
    
}