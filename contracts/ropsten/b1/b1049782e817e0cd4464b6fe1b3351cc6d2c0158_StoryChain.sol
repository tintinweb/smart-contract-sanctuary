pragma solidity ^0.4.24;

contract StoryChain {

	struct Story {
		address publisher;
		string story;
		uint price;
		uint prev;
	}
	Story[] public stories;

	constructor () public {
	    uint maxInt = 0;
	    maxInt -= 1;
		stories.push(Story({publisher:msg.sender, story:&quot;昔々あるところに&quot;, price:0, prev: maxInt})); /* default prev: 2**256-1 */
	}

	function addStory(uint _prev, string _story) public payable {
	    require(_prev < stories.length);
		stories.push(Story({publisher:msg.sender, story:_story, price:0, prev:_prev}));
	}

	function vote(uint _storyIndex) public payable {
        stories[_storyIndex].price += msg.value;
        stories[_storyIndex].publisher.transfer(msg.value);
	}

	function getStoriesLength() public view returns (uint) {
		return stories.length;
	}
}