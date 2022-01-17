/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// This contract is for illustration purposes only.
// Please do not repeat the code from here, and even more so avoid using loops in your contracts.

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

contract Tutorial {
    mapping(address => string[]) private tweets;

    //mapping(address => mapping(uint => string[])) private test;

    /*
        @notice Adds tweet in Ethereum blochain by public key 
        @dev We call _insert where the check for the existence of a tweet passes and, if it does not exist, adds
        @param tweet as a string 
    */
    function addTweet(string memory _tweet) external payable {
        _insert(msg.sender, _tweet);
    }

    /*
        @notice Remove tweet by _tweet
        @dev We call _burn 
        @param tweet as a string 
    */
    function removeTweet(string memory _tweet) external payable {
        _burn(msg.sender, _tweet);
    }

    /*
        @notice Retrieves an array of tweets for given Ethereum address
        @param _address as a string 
    */
    function getTweets(address _address) public view returns (string[] memory) {
        return tweets[_address];
    }

    /*
        @notice Inserts value to array stored in a mapping. If there is such a tweet throws an error
        @param _address adress owner
        @param string memory _tweet text
     */
    function _insert(address _address, string memory _tweet) internal {
        require(
            !findTweet(tweets[_address], _tweet),
            "This entry already exists"
        );

        tweets[_address].push(_tweet);
    }

    /*  @notice Checks if such a twitch exists and, if it exists, deletes by index
        @dev Move the last element to the deleted spot. 
        @param _address adress owner
        @param string memory _tweet text
     */
    function _burn(address _address, string memory _tweet) internal {
        require(
            findTweet(tweets[_address], _tweet),
            "There is no such meaning"
        );

        uint256 index = findIndexTweet(tweets[_address], _tweet) - 1;
        uint256 length = tweets[_address].length;

        tweets[_address][index] = tweets[_address][length - 1];
        tweets[_address].pop();
    }

    /*
        @dev An internal function to help find the index of a tweet
        @param _address adress owner
        @param string memory _tweet text
     */
    function findTweet(string[] memory _tweets, string memory _tweet)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _tweets.length; i++) {
            if (compareTweets(_tweets[i], _tweet)) {
                return true;
            }
        }

        return false;
    }

    /* 
        @dev Internal function, checks if there is such a tweet
        @param _address adress owner
        @param string memory _tweet text
     */
    function findIndexTweet(string[] memory _tweets, string memory _tweet)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < _tweets.length; i++) {
            if (compareTweets(_tweets[i], _tweet)) {
                return i + 1;
            }
        }

        return 0;
    }

    /* 
        @dev Purple a function that compares two tweets
        @param string memory _tweet1 text
        @param string memory _tweet2 text
     */
    function compareTweets(string memory _tweet1, string memory _tweet2)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encode(_tweet1)) == keccak256(abi.encode(_tweet2));
    }
}