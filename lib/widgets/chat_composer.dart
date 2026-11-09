import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';

/// Message input zone with glowing focus border and send action button.
///
/// Designed to remain clear above the virtual keyboard on Android and iOS
/// while supporting rapid keyboard submission on Windows desktop.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSend,
    this.isBusy = false,
    this.hintText = 'Écrire un message de démonstration à Nyx...',
    this.onFocusChanged,
  });

  final ValueChanged<String> onSend;
  final bool isBusy;
  final String hintText;
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _textController.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (_hasFocus != _focusNode.hasFocus) {
      setState(() => _hasFocus = _focusNode.hasFocus);
      widget.onFocusChanged?.call(_hasFocus);
    }
  }

  void _onTextChange() {
    setState(() {});
  }

  void _submit() {
    final trimmed = _textController.text.trim();
    if (trimmed.isEmpty || widget.isBusy) {
      return;
    }
    _textController.clear();
    widget.onSend(trimmed);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textController.removeListener(_onTextChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _textController.text.trim().isNotEmpty && !widget.isBusy;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: NexusColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _hasFocus
              ? NexusColors.neonViolet
              : NexusColors.borderSubtle,
          width: _hasFocus ? 1.4 : 1.0,
        ),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: NexusColors.neonViolet.alphaFactor(0.22),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: !widget.isBusy,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                fontSize: 15,
                color: NexusColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.isBusy
                    ? 'Nyx prépare une réponse de démonstration...'
                    : widget.hintText,
                hintStyle: const TextStyle(color: NexusColors.textMuted),
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Envoyer le message',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: canSend
                    ? const LinearGradient(
                        colors: [
                          NexusColors.neonViolet,
                          NexusColors.electricViolet,
                        ],
                      )
                    : null,
                color: canSend ? null : NexusColors.surfaceElevated,
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: NexusColors.neonViolet.alphaFactor(0.42),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                key: const ValueKey<String>('chat_send_button'),
                onPressed: canSend ? _submit : null,
                icon: widget.isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NexusColors.lavenderGlow,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: canSend
                            ? NexusColors.textPrimary
                            : NexusColors.textMuted,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
