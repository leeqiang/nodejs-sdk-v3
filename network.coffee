# QQ qun
# 开放平台的http协议发送包
# Author: Lee
# Date: 2013 - 5 - 29
# Email: qiang@teambition.com

http = require('http')
https = require('https')
querystring = require('querystring')

Sign = require('./signature')


class Network

  # 公共参数
  # * openid: 用户ID - appid + qq
  # * openkey: session key
  # * appid: 应用ID
  # * sig: 签名密钥
  # * pf: 应用的来源平台
  # ? format: API返回的数据格式, xml || json(d)
  # ? userip: 用户的IP

  # production: openapi.tencentyun.com
  # development: 119.147.19.43

  serverIp: '119.147.19.43'
  secret: ''
  port: 80
  _requestFunc: http
  sigName: 'sig'

  constructor: (@secret, @serverIp, sigName) ->
    # api constructor
    @sigName = sigName if sigName

  _makeSendData: (method, apiPath, params) ->
    # 构造数据

    sig = Sign.makeSig(method, apiPath, params, @secret)
    params[@sigName] = sig
    return Sign.urlencode(params)

  _send: (apiPath, params, method, protocol, next) ->
    # 提供统一的调用接口

    protocol = protocol.toLowerCase()
    method = method.toLowerCase()

    if method not in ['post', 'get']
      throw new TypeError('method invalid: ' + method)

    if ':' in @serverIp
      infos = @serverIp.split(':')
      @serverIp = infos[0]
      @port = infos[1]

    httpOptions =
      host : @serverIp
      method: method.toUpperCase()
      path : apiPath
      port : @port

    if protocol is 'https'
      httpOptions.port = 443
      @_requestFunc = https

    if method is 'post'
      httpOptions.headers = {}
      httpOptions.headers['Content-Length'] = Buffer.byteLength(params)
      httpOptions.headers['Content-type'] = 'application/x-www-form-urlencoded'
    else httpOptions.path += "?#{params}"

    request = @_requestFunc.request(httpOptions, (response) =>
      response.setEncoding('utf8')
      response.on('data', next)
    )
    request.on 'error', (err) ->
      throw new Error('request error: ' + err)
    request.end(params)

  open: (apiPath, params, method, protocol, next) ->
    # 外部调用

    if protocol not in ['http', 'https']
      throw new TypeError('protocal invalid: ' + protocol)

    params = @_makeSendData(method, apiPath, params)
    @_send(apiPath, params, method, protocol, next)

module.exports = Network