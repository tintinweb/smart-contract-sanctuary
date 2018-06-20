pragma solidity ^0.4.18;

//this is the smart contract for the Hundred Ether Wall
//please take note that the contract contains a constructor That
//declares the contract owner, only the contract owner can withdraw funds
//if you want to see the methods being called on
//take a look at the HomePage.js component

contract HundredEtherWall {
  address public contractOwner;

  //a modifier can be used on methods to inherit the require
  modifier onlyContractOwner {
    require(msg.sender == contractOwner);
    _;
  }

  uint public constant pixelPrice = 80000000000000;
  uint public constant pixelsPerCell = 625;
  address receiver;

  //event for buying an ad
  event Buy (
    uint indexed idx,
    address owner,
    uint x,
    uint y,
    uint width,
    uint height
  );

  //event for updating an ad
  event Update (
    uint indexed idx,
    string link,
    string ipfsHash,
    string title
  );

  //event for setting an add off or on sale
  event SetSale (
    uint indexed idx,
    bool forSale,
    uint marketPrice
  );

  //event for setting an add off or on sale
  event MarketBuy (
    uint indexed idx,
    address owner,
    bool forSale,
    uint marketPrice
  );

  //event for setting an add off or on active
  event SetActive (
    uint indexed idx,
    bool active
  );

  //Contents on an ad
  struct Ad {
    address owner;
    uint width;
    uint height;
    uint x;
    uint y;
    string title;
    string link;
    string ipfsHash;
    bool forSale;
    bool active;
    uint marketPrice;
  }

  //the actual array of the ads
  Ad[] public ads;

  //2d array of booleans to set true whenever an ad is bought
  //this is used in the buy() method to check if the spot is availible or not
  bool[40][50] public grid;

  //the constructor
  constructor() public {
      contractOwner = msg.sender;
  }

  //payable function to trigger the purchase
  function buy(uint _x, uint _y, uint _width, uint _height, string _title, string _link, string _ipfsHash) public payable returns (uint idx) {
    //calculate the price of the ad
    uint price = _width * _height * pixelPrice;

    //set restrictions
    require(price > 0);
    require(msg.value >= price);
    require(_width % 25 == 0);
    require(_height % 25 == 0);

    //fill 2d array with true fo the purchased blocks
    //if the block is already true (means its already bought)
    // -> revert()
    for(uint i = 0; i < _width / 25; i++) {
        for(uint j = 0; j < _height / 25; j++) {
            if (grid[_x / 25 + i][_y / 25 + j]) {
                revert();
            }
            grid[_x / 25 + i][_y / 25 + j] = true;
        }
    }

    //store the ad, return the index
    Ad memory ad = Ad(msg.sender, _x, _y, _width, _height, _title, _link, _ipfsHash, false, true, price);
    idx = ads.push(ad) - 1;

    //trigger transaction with the buy event
    emit Buy(idx, msg.sender, _x, _y, _width, _height);

    return idx;
  }

  //function for updating an ad
  function update(uint _idx, string _title, string _link, string _ipfsHash) public {
    //get add with index from parameter
    Ad storage ad = ads[_idx];
    require(msg.sender == ad.owner || msg.sender == contractOwner);

    //set parameters to repalce the old content
    ad.link = _link;
    ad.ipfsHash = _ipfsHash;
    ad.title = _title;

    //trigger transaction without cost
    emit Update(_idx, ad.link, ad.ipfsHash, ad.title);
  }

  //function for setting an ad for sale
  function setSale(uint _idx, bool _sale, uint _marketPrice) public {
    //get add with index from parameter
    Ad storage ad = ads[_idx];
    require(msg.sender == ad.owner);

    ad.forSale = _sale;
    ad.marketPrice = _marketPrice;

    emit SetSale(_idx, ad.forSale, ad.marketPrice);
  }

  //method for buying an ad on the market. Has to change owner only
  //set the forSale bool false again
  function marketBuy(uint _idx) public payable {
    //get add with index from parameter
    Ad storage ad = ads[_idx];
    //set restrictions
    require(msg.sender != ad.owner);
    require(msg.value > 0);
    require(msg.value >= ad.marketPrice);
    require(ad.forSale == true);

    receiver = ad.owner;

    ad.owner = msg.sender;
    ad.forSale = false;

    //set the ad back to its original price
    uint price = ad.width * ad.height * pixelPrice;

    receiver.transfer(msg.value);
    emit MarketBuy(_idx, ad.owner, ad.forSale, price);
  }

  //function for setting an ad active or inactive
  function setActive(uint _idx, bool _active) public onlyContractOwner {
    //get add with index from parameter
    Ad storage ad = ads[_idx];

    ad.active = _active;

    emit SetActive(_idx, ad.active);
  }

  //returns the total length of ads, used for looping over the ads in the homepage.js
  //note: this does only return an integer
  function getAds() public constant returns (uint) {
    return ads.length;
  }

  //transfers the full funds to the contract owner
  //contractOwner === deployer of the contract
  function withdraw() public onlyContractOwner {
    contractOwner.transfer(address(this).balance);
  }
}