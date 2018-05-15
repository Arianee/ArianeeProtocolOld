pragma solidity ^0.4.21;

import "./ERC721.sol";
import "./ERC721BasicToken.sol";


/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ArianeeProtocol is ERC721, ERC721BasicToken {
  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  // Mapping from token id to bool as for request as transfer knowing the tokenkey
  mapping (uint256 => bool) public isTokenRequestable;  

  // Mapping from token id to TokenKey (if requestable)
  mapping (uint256 => bytes32) public encryptedTokenKey;  

  /**
   * @dev Constructor function
   */
  constructor() public {
    name_ = "Arianee";
    symbol_ = "SmartAsset";
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() public view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() public view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /// @notice Returns a list of all Token IDs assigned to an address.
  /// @param _owner The owner whose tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
  ///  expensive,
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  /*
  function tokensOfOwner(address _owner) external view returns(string[][] result) {
      uint256 tokenCount = balanceOf(_owner);

      if (tokenCount == 0) {
          // Return an empty array
          return new uint256[](0);
      } else {
          //uint256[] memory result = new uint256[](tokenCount);
          //uint256 resultIndex = 0;

          uint256 tokenId;

          for (tokenId = 0; tokenId < tokenCount; tokenId++) {
                  result[tokenId]['tokenId'] = tokenOfOwnerByIndex(_owner,tokenId);
                  result[tokenId]['URI'] = tokenURI(tokenId);
          }

          return result;
      }
  }  
  */
  
  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * @dev Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * @dev Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * @dev Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Public function to mint a specific token and assign metadata
   * @param _for receiver of the token to mint
   * @param value json metadata (in blockchain for now)
   */
  function createFor(address _for, string value) public returns (uint256) {
    uint256 currentToken = allTokens.length;

    _mint(_for ,currentToken);
    _setTokenURI(currentToken,value);

    // TODO return false if value not well formatted
    return currentToken;

  }


  /**
   * @dev Public function to mint a specific token and assign metadata with token for request
   * @param _for receiver of the token to mint
   * @param value json metadata (in blockchain for now)
   */
  function createForWithToken(address _for, string value, bytes32 _encryptedTokenKey) public returns (uint256) {
    uint256 currentToken = createFor(_for, value);

    encryptedTokenKey[currentToken] = _encryptedTokenKey;
    isTokenRequestable[currentToken] = true;

    // TODO return false if value not well formatted
    return currentToken;

  }

  /**
   * @dev Public function to mint a specific token for sender and assign metadata
   * @param value json metadata (in blockchain currently)
   */
  function create (string value) public returns (uint256) {
    return createFor(msg.sender,value);
  }

  /**
   * @dev Public function to check if a token is requestable
   * @param _tokenId uint256 ID of the token to check
   */
  function isRequestable(uint256 _tokenId) public view returns (bool) {
    return isTokenRequestable[_tokenId];
  }

  /**
   * @dev Public function to set a token requestable (or not)
   * @param _tokenId uint256 ID of the token to check
   * @param _encryptedTokenKey bytes32 representation of keccak256 secretkey
   * @param _requestable bool to set on or off   
   */
  function setRequestable(uint256 _tokenId, bytes32 _encryptedTokenKey, bool _requestable) public onlyOwnerOf(_tokenId) returns (bool) {

    if (_requestable) {
      encryptedTokenKey[_tokenId] = _encryptedTokenKey;
      isTokenRequestable[_tokenId] = true;
    } else {
      isTokenRequestable[_tokenId] = false;    
    }

    return true;
  }  

  /**
   * @dev Checks if token id is requestable and correct key is given
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canRequest(uint256 _tokenId, string encryptedKey) {
    require(isTokenRequestable[_tokenId]&&keccak256(encryptedKey) == encryptedTokenKey[_tokenId]);
    _;
  }
  

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * @dev Requires the msg sender to have the correct tokenKey and token id is requestable
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function requestFrom(address _from, address _to, uint256 _tokenId, string encryptedKey) public canRequest(_tokenId, encryptedKey) {

    transferFrom_(_from, _to, _tokenId);

  }




}
