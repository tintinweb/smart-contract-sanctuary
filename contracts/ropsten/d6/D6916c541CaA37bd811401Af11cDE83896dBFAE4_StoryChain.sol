pragma solidity ^0.4.24;

contract StoryChain {

	struct Story {
		address publisher;
		string story;
		uint price;
		uint prev;
	}
	Story[] public stories;
	
	constructor (string _story) public {
	    bytes memory storyBytes = bytes(_story);
	    uint maxInt = 0;
	    maxInt -= 1;
	    if (storyBytes.length == 0) {
	        _story = &quot;昔々あるところに&quot;;
	    }
		stories.push(Story({publisher:msg.sender, story:_story, price:0, prev: maxInt})); /* default prev: 2**256-1 */
	}

	function addStory(uint _prev, string _story) public {
	    require(_prev < stories.length, &quot;連結先のstoryが存在しません。&quot;);
	    require(stories[_prev].publisher != msg.sender, &quot;同じチェーンに連続してstoryの追加はできません。&quot;);
		stories.push(Story({publisher:msg.sender, story:_story, price:0, prev:_prev}));
	}

	function vote(uint _storyIndex) public payable {
	    require(stories[_storyIndex].publisher != msg.sender, &quot;自身の投稿には投票できません。&quot;);
        stories[_storyIndex].price += msg.value;
        stories[_storyIndex].publisher.transfer(msg.value);
	}

	function getStoriesLength() public view returns (uint) {
		return stories.length;
	}
}