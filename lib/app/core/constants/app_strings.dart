class AppStrings {
  AppStrings._();

  // App
  static const appTitle = 'YouTube Downloader';

  // Labels gerais
  static const labelVideo = 'Video';
  static const labelAudio = 'Audio';
  static const labelAudioOnly = 'Somente Audio';
  static const labelBestAvailable = 'Melhor disponivel';
  static const labelNoQualityAvailable = 'Nenhuma opcao disponivel';
  static const labelUnavailable = 'Indisponivel';

  // URL input
  static const labelUrlInput = 'URL do YouTube';
  static const labelUrlHint = 'Cole o link do video ou playlist aqui...';
  static const labelFetch = 'Obter Info';
  static const labelFetching = 'Buscando...';

  // Download button
  static const labelDownload = 'Baixar';
  static const labelDownloading = 'Baixando...';
  static const labelDownloadPlaylist = 'Baixar Playlist';
  static const labelCancel = 'Cancelar';

  // Quality / type selector
  static const labelTypeAndQuality = 'Tipo e Qualidade';
  static const labelDownloadType = 'Tipo de Download';
  static const labelPlaylistQualityNote =
      'Playlist: sera usada a melhor qualidade disponivel para cada video';

  // Video info card
  static const labelNoTitle = 'Sem titulo';
  static const labelPlaylist = 'Playlist';
  static const labelVideos = 'videos';

  // Download progress
  static const statusCompleted = 'Download concluido!';
  static const statusCancelled = 'Download cancelado';
  static const statusFetching = 'Buscando informacoes...';
  static const statusWaiting = 'Aguardando...';
  static const statusError = 'Erro no download';
  static const statusPercent = '% concluido';

  // Settings page
  static const labelSettings = 'Configuracoes';
  static const labelDownloadFolder = 'Pasta de Download';
  static const labelDefaultType = 'Tipo Padrao';
  static const labelDefaultQuality = 'Qualidade Padrao';
  static const labelNoFolderSelected = 'Nenhuma pasta selecionada';
  static const labelChangeFolder = 'Alterar Pasta';
  static const labelSave = 'Salvar';
  static const labelSaving = 'Salvando...';
  static const labelSelectFolderDialog = 'Selecionar pasta de download';

  // Snackbar titles
  static const snackSuccess = 'Sucesso';
  static const snackError = 'Erro';
  static const snackWarning = 'Atencao';
  static const snackPermissionDenied = 'Permissao negada';

  // Snackbar messages
  static const msgNoUrl = 'Cole uma URL do YouTube antes de buscar';
  static const msgNoVideoInfo = 'Busque as informacoes do video primeiro';
  static const msgSelectQuality = 'Selecione uma qualidade antes de baixar';
  static const msgNoDownloadFolder = 'Informe a pasta de download';
  static const msgVideoDownloadedPrefix = 'Video baixado com sucesso!\nSalvo em: ';
  static const msgPlaylistDownloadedPrefix = 'Playlist baixada com sucesso!\nSalvo em: ';
  static const msgVideoInfoError = 'Nao foi possivel obter as informacoes do video';
  static const msgLoadSettingsError = 'Falha ao carregar configuracoes';
  static const msgSaveSettingsError = 'Falha ao salvar configuracoes';
  static const msgDownloadError = 'Falha no download';
  static const msgPlaylistDownloadError = 'Falha ao baixar playlist';
  static const msgPermissionDenied =
      'Conceda permissao de armazenamento nas configuracoes do sistema';

  // yt-dlp settings
  static const labelYtdlpSection = 'Motor de Download';
  static const labelPreferYtdlp = 'Usar yt-dlp (mais confiavel)';
  static const labelPreferYtdlpSubtitle =
      'Requer download do binario yt-dlp (~10 MB) no primeiro uso (Windows: yt-dlp.exe, Android: ARM64)';
  static const labelDownloadYtdlp = 'Baixar yt-dlp agora';
  static const labelYtdlpReady = 'yt-dlp instalado e pronto';
  static const labelYtdlpNotInstalled = 'yt-dlp nao instalado';
  static const msgYtdlpDownloading = 'Baixando binario yt-dlp...';
  static const msgYtdlpSuccess = 'yt-dlp instalado com sucesso!';
  static const msgYtdlpError = 'Falha ao instalar yt-dlp';
  static const labelUpdateYtdlp = 'Atualizar yt-dlp';
  static const msgYtdlpUpdating = 'Atualizando yt-dlp...';
  static const msgYtdlpUpdateSuccess = 'yt-dlp atualizado com sucesso!';
  static const msgYtdlpUpdateError = 'Falha ao atualizar yt-dlp';

  // Tooltip
  static const tooltipSettings = 'Configuracoes';
}
