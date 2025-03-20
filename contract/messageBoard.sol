
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DecentralizedMessageBoard
 * @dev Smart contract for a decentralized message board where users can post and manage messages
 */
contract DecentralizedMessageBoard {
    // Struct to store message data
    struct Message {
        uint256 id;
        address author;
        string content;
        uint256 timestamp;
        bool isActive;
        uint256 likes;
        uint256[] replies;
    }

    // State variables
    uint256 private nextMessageId;
    mapping(uint256 => Message) public messages;
    mapping(address => uint256[]) public userMessages;
    mapping(uint256 => mapping(address => bool)) public userLikes;
    
    // Events
    event MessagePosted(uint256 indexed messageId, address indexed author, uint256 timestamp);
    event MessageDeleted(uint256 indexed messageId, address indexed author, uint256 timestamp);
    event MessageLiked(uint256 indexed messageId, address indexed liker, uint256 timestamp);
    event ReplyAdded(uint256 indexed parentId, uint256 indexed replyId, address indexed author);

    /**
     * @dev Constructor to initialize the message board
     */
    constructor() {
        nextMessageId = 1;
    }

    /**
     * @dev Post a new message to the board
     * @param _content The content of the message
     * @return The ID of the newly created message
     */
    function postMessage(string memory _content) public returns (uint256) {
        require(bytes(_content).length > 0, "Content cannot be empty");
        require(bytes(_content).length <= 1000, "Content is too long");
        
        uint256 messageId = nextMessageId++;
        
        messages[messageId] = Message({
            id: messageId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            isActive: true,
            likes: 0,
            replies: new uint256[](0)
        });
        
        userMessages[msg.sender].push(messageId);
        
        emit MessagePosted(messageId, msg.sender, block.timestamp);
        
        return messageId;
    }

    /**
     * @dev Reply to an existing message
     * @param _parentId The ID of the parent message
     * @param _content The content of the reply
     * @return The ID of the newly created reply message
     */
    function replyToMessage(uint256 _parentId, string memory _content) public returns (uint256) {
        require(messages[_parentId].isActive, "Parent message does not exist or is deleted");
        
        uint256 replyId = postMessage(_content);
        messages[_parentId].replies.push(replyId);
        
        emit ReplyAdded(_parentId, replyId, msg.sender);
        
        return replyId;
    }

    /**
     * @dev Like a message
     * @param _messageId The ID of the message to like
     */
    function likeMessage(uint256 _messageId) public {
        require(messages[_messageId].isActive, "Message does not exist or is deleted");
        require(!userLikes[_messageId][msg.sender], "You have already liked this message");
        require(messages[_messageId].author != msg.sender, "You cannot like your own message");
        
        messages[_messageId].likes++;
        userLikes[_messageId][msg.sender] = true;
        
        emit MessageLiked(_messageId, msg.sender, block.timestamp);
    }

    /**
     * @dev Delete a message (only the author can delete their own message)
     * @param _messageId The ID of the message to delete
     */
    function deleteMessage(uint256 _messageId) public {
        require(messages[_messageId].isActive, "Message does not exist or is already deleted");
        require(messages[_messageId].author == msg.sender, "Only the author can delete their message");
        
        messages[_messageId].isActive = false;
        
        emit MessageDeleted(_messageId, msg.sender, block.timestamp);
    }

    // /**
    //  * @dev Get a message by its ID
    //  * @param _messageId The ID of the message to retrieve
    //  * @return Message struct containing the message data
    //  */
    function getMessage(uint256 _messageId) public view returns (
        uint256 id,
        address author,
        string memory content,
        uint256 timestamp,
        bool isActive,
        uint256 likes,
        uint256[] memory replies
    ) {
        Message storage message = messages[_messageId];
        require(message.isActive || message.author == msg.sender, "Message does not exist or is deleted");
        
        return (
            message.id,
            message.author,
            message.content,
            message.timestamp,
            message.isActive,
            message.likes,
            message.replies
        );
    }

    /**
     * @dev Get all messages by a specific user
     * @param _user The address of the user
     * @return Array of message IDs posted by the user
     */
    function getUserMessages(address _user) public view returns (uint256[] memory) {
        return userMessages[_user];
    }

    /**
     * @dev Get total number of messages on the board
     * @return The total number of messages (including deleted ones)
     */
    function getTotalMessages() public view returns (uint256) {
        return nextMessageId - 1;
    }

    /**
     * @dev Get the replies to a specific message
     * @param _messageId The ID of the message
     * @return Array of reply message IDs
     */
    function getReplies(uint256 _messageId) public view returns (uint256[] memory) {
        require(messages[_messageId].id == _messageId, "Message does not exist");
        
        return messages[_messageId].replies;
    }

    /**
     * @dev Check if a user has liked a specific message
     * @param _messageId The ID of the message
     * @param _user The address of the user
     * @return Boolean indicating whether the user has liked the message
     */
    function hasUserLiked(uint256 _messageId, address _user) public view returns (bool) {
        return userLikes[_messageId][_user];
    }
}
