/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract DistributedDictionary {

    constructor(){
        initWithWords();
    }

    struct Post {
        uint id;
        string wordMeaning;
        int votes;
        address author;
    }

    struct Word{
        Post[] posts;
    }

    mapping (string => Word) private wordsMap;
    string[] private wordsArray; // mapping does not preserve original words, so we also have words as array.
    

    // ---------- ---------- state changing functions ---------- ----------
    function addPost(string memory newWord, string memory wordMeaning) public{
        // adds Post to a word, crates word if not exists
        
        // add word if not exists
        if(!isWordExists(newWord)){
            wordsArray.push(newWord);
        }

        // create post
        Post memory newPost = Post(
            {
                wordMeaning: wordMeaning,
                author: msg.sender,
                votes: 0,
                id: wordsMap[newWord].posts.length
            }
        );

        // add new post to word map
        wordsMap[newWord].posts.push(newPost);
    }


    function votePost(string memory word, uint votePostId, bool voteType) public{
        // up or down votes a post
        for (uint i = 0; i < wordsMap[word].posts.length; i++) {
            if(wordsMap[word].posts[i].id == votePostId){
                if(voteType){
                    wordsMap[word].posts[i].votes += 1;
                }
                else{
                    wordsMap[word].posts[i].votes -= 1;
                }
                break;
            }
        }
    }
    // ---------- ---------- ---------- ---------- ----------



    // ---------- ---------- post getters ---------- ----------
    function getPostsByWord(string memory word) view public returns (Post[] memory){
        // returnes posts for a word
        return wordsMap[word].posts;
    }
    
    function getPostsByWords(string[] memory words) view public returns (Word[] memory){
        // returnes posts for multiple words
        Word[] memory tempWords = new Word[](words.length);
        
        for (uint i = 0; i < words.length; i++) {
            tempWords[i] = wordsMap[words[i]];
        }
    
        return tempWords;
    }


    function getPostsByWordIndex(uint index) view public returns (Post[] memory){
        // returnes posts for a word by word index
        return wordsMap[wordsArray[index]].posts;
    }

    function getPostsByWordIndexes(uint[] memory indexes) view public returns (Word[] memory){
        // returnes posts for multiple words by word indexes
        Word[] memory tempWords = new Word[](indexes.length);
        
        for (uint i = 0; i < indexes.length; i++) {
            tempWords[i] = wordsMap[wordsArray[indexes[i]]];
        }
    
        return tempWords;
    }


    function getPostsBetween(string memory word, uint start, uint end) view public returns (Post[] memory){
        // returnes posts in between a range for a word
        Post[] memory tempPosts = new Post[](end - start);
        
        uint j = 0;
        for (uint i = start; i < end; i++) {
            tempPosts[j] = wordsMap[word].posts[i];
            j++;
        }
    
        return tempPosts;
    } 
    // ---------- ---------- ---------- ---------- ----------
    


    // ---------- ---------- word getters ---------- ----------
    function getWordsBetween(uint start, uint end) view public returns (string[] memory){
        // returnes words in between a range
        string[] memory temp = new string[](end - start);
        
        uint j = 0;
        for (uint i = start; i < end; i++) {
            temp[j] = wordsArray[i];
            j++;
        }
    
        return temp;
    } 
    
    function getLastNWords(uint n) view public returns (string[] memory){
        // returnes last N amount of words
        string[] memory temp = new string[](n);
        for (uint i = 0; i < n; i++) {
            temp[i] = wordsArray[wordsArray.length - (i+1)];
        }

        return temp;
    }

    function getWordByIndex(uint index) view public returns (string memory){
        // returnes word by index
        return wordsArray[index];
    }
    
    function getAllWords() view public returns (string[] memory){
        // returnes all saved words
        return wordsArray;
    }

    function getWordCount() view public returns (uint){
        // returnes word array length
        return wordsArray.length;
    }
    

    function isWordExists(string memory word) view public returns (bool){
        // returnes true if a word exists
        if(wordsMap[word].posts.length > 0){
            return true;
        }
        else{
            return false;
        }
    }
    // ---------- ---------- ---------- ---------- ----------  



    // ---------- ---------- other ---------- ----------
    function initWithWords() private {
        // for initialising contract with words
        addPost("test", "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor.");
        addPost("test", "totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.");
        addPost("test", "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit.");

        addPost("Ethereum", "Ethereum is the community-run technology powering the cryptocurrency, ether (ETH) and thousands of decentralized applications.");
        addPost("cake", "The cake is a lie!");
        addPost("muz", "A fruit");

        addPost("Distributed Dictionary", "A user-created dictionary that runs entirely on the blockchain without the need for a centralized backend.");
        votePost("Distributed Dictionary", 0, true);
    }
    // ---------- ---------- ---------- ---------- ----------  

}