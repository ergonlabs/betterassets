package com.ergonlabs.betterassets

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.io.FilterInputStream
import java.io.InputStream
import java.util.*

class StreamWrapper(val stream: InputStream) : FilterInputStream(stream) {
    val length = stream.skip(Long.MAX_VALUE) // hack to get length
    var position: Long = 0L;

    init {
        moveTo(0L);
    }

    fun moveTo(newPos: Long) {
        stream.reset()
        if (newPos != 0L)
            stream.skip(newPos)
        position = newPos
    }

    override fun read(): Int {
        val read = super.read()
        position++
        return read
    }

    override fun read(b: ByteArray?, off: Int, len: Int): Int {
        val read = super.read(b, off, len)
        position += read
        return read
    }
}

/** BetterassetsPlugin */
public class BetterassetsPlugin() : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding
    private var streams: MutableMap<String, StreamWrapper> = mutableMapOf()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        binding = flutterPluginBinding
        channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "betterassets")
        channel.setMethodCallHandler(this);
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "betterassets")
            channel.setMethodCallHandler(BetterassetsPlugin())
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method.startsWith("stream.")) {
            onStreamMethodCall(call, result)
        } else {
            var path = "flutter_assets"
            var morePath = call.argument<String>("path");
            if (morePath != null && morePath.length > 0)
                path = "$path/$morePath"
            if (call.method == "list") {
                val files = binding.applicationContext.assets.list(path)
                result.success(files.toList())
            } else if (call.method == "open") {
                val mode = (call.argument<Int>("mode") ?: 1)
                val stream = binding.applicationContext.assets.open(path, mode)
                val key = UUID.randomUUID().toString();
                streams[key] = StreamWrapper(stream);
                result.success(key)
            } else if (call.method == "getPlatformVersion") {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            } else {
                result.notImplemented()
            }
        }
    }

    private fun onStreamMethodCall(call: MethodCall, result: Result) {
        val key = call.argument<String>("key");
        val stream = streams[key];
        if (call.method == "stream.close") {
            stream?.close()
            channel.invokeMethod("close", mapOf(Pair("key", key)))
            streams.remove(key)
            result.success(null)
        } else if (call.method == "stream.length") {
            result.success(stream?.length)
        } else if (call.method == "stream.position") {
            val newValue = call.argument<Long>("position")
            if (newValue != null) {
                stream?.moveTo(newValue);
            }
            result.success(stream?.position)
        } else if (call.method == "stream.read") {
            val len = call.argument<Int>("bytes")
            var b = ByteArray(len!!);
            val read = stream?.read(b, 0, len)!!
            if (len != read) {
                b = b.copyOf(read)
            }
            result.success(b)
        } else if (call.method == "stream.readByte") {
            result.success(stream?.read())
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

