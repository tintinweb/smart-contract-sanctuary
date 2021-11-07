// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ChainlinkClient.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract APIConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;
  
    uint256 public volume;
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel   
     * Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */
    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
    }
    
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    //  function GGG() public returns(uint) {
    //      requestVolumeData();
    //      return volume;
    //  }
    // function concatenate(string memory s1, string memory s2) public pure returns (string memory) {
    //     return string(abi.encodePacked(s1, s2));
    // }
    // function Display(string memory tempadd) public view returns(string memory) {
    //     string memory s1 = tempadd;
    //     string memory s2 = "https://rjv935fe1plq.usemoralis.com:2053/server/functions/getTotalEggs?_ApplicationId=NahroQDmEpUJWxPxY8QT3QSgkdqUAalvARDVKeLk&account=";
    //     string memory temp = string(abi.encodePacked(s1, s2));
    //     return temp;
    // }
    function requestVolumeData(string memory tempadd) public returns (bytes32 requestId) 
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        string memory s1 = tempadd;
        string memory s2 = "https://rjv935fe1plq.usemoralis.com:2053/server/functions/getTotalEggs?_ApplicationId=NahroQDmEpUJWxPxY8QT3QSgkdqUAalvARDVKeLk&account=";
        string memory temp = string(abi.encodePacked(s2, s1));
        
        
        // Set the URL to perform the GET request on
        request.add("get", temp);
        
        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        request.add("path", "result");
        
        // Multiply the result by 1000000000000000000 to remove decimals
        // int timesAmount = 10**18;
        // request.addInt("times", timesAmount);
        
        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }
    
    /**
     * Receive the response in the form of uint256
     */ 
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId)
    {
        volume = _volume;
    }
    event BuyEggsDB(uint beggs, address account);
    event SellEggsDB(uint seggs, address account);
    address public token = 0xa0dd1746E03d7b58F25E86Bc7DefA532831f7e36;
    address public devaddress = 0x3f17817418dbF4B2257c06f3BB8EbA9009d2f28C;  //AdminContract Address where the token holds
   
   
    function BuyEggs(uint amount, uint _fees) external {

        IERC20(token).transferFrom(msg.sender, address(this) , amount);
        IERC20(token).transferFrom(msg.sender, devaddress , _fees);
        uint beggs = amount;
        emit BuyEggsDB(beggs, msg.sender);
        
    }
    
    function SellEggs(uint _eggs, string memory _temp) external {
        requestVolumeData(_temp);
        require(volume >= _eggs, 'Eggs Amount is not valid');
        uint amount = _eggs;
        uint seggs = _eggs;
        IERC20(token).transfer(msg.sender, amount);
        emit SellEggsDB(seggs, msg.sender);
        
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}